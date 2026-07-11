# frozen_string_literal: true

# Page de lecture publique d'une carte : /m/:slug
class Views::PublicMaplines::Show < Views::Base
  def initialize(mapline:)
    @mapline = mapline
  end

  def view_template
    render Views::Layout.new(title: @mapline.title) do
      if owner_preview?
        div(class: "mb-6 rounded-md bg-notice-bg px-4 py-3 text-sm text-notice-ink") do
          plain "Aperçu — cette carte est en #{@mapline.status_label.downcase}. "
          Link("Gérer la carte", edit_mapline_path(@mapline))
        end
      end

      article(class: "flex flex-col gap-8") do
        header do
          h1(class: "font-serif text-[clamp(1.8rem,4vw,2.6rem)] leading-tight") { @mapline.title }
          p(class: "mt-2 text-muted") do
            plain "par "
            Link(@mapline.user.display_name, profile_path(@mapline.user.slug))
          end
          if @mapline.description.present?
            p(class: "mt-4 max-w-2xl text-lg") { @mapline.description }
          end
        end

        if @mapline.key_dates.any?
          Timeline(key_dates: @mapline.key_dates)
        end

        section(
          data: {
            controller: "map",
            map_center_lng_value: @mapline.center_lng,
            map_center_lat_value: @mapline.center_lat,
            map_zoom_value: @mapline.zoom
          }
        ) do
          div(data: { map_target: "canvas" },
            class: "h-[480px] w-full overflow-hidden rounded-2xl border border-line")
        end

        render_sources
      end
    end
  end

  private

  def owner_preview?
    !@mapline.public? && Current.user == @mapline.user
  end

  def render_sources
    return if @mapline.sources.empty?

    section do
      h2(class: "mb-4 text-xl font-semibold") { "Sources" }
      ul(class: "flex flex-col gap-3") do
        @mapline.sources.each do |source|
          li(class: "rounded-lg border border-line bg-surface p-4") do
            div(class: "font-semibold") do
              if source.url.present?
                a(href: source.url, target: "_blank", rel: "noopener") { source.title }
              else
                plain source.title
              end
            end
            if source.author.present?
              p(class: "text-sm text-muted") { source.author }
            end
          end
        end
      end
    end
  end
end
