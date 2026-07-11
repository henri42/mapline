# frozen_string_literal: true

# Profil auteur public : /@:slug
class Views::Profiles::Show < Views::Base
  def initialize(user:, maplines:, owner:)
    @user = user
    @maplines = maplines
    @owner = owner
  end

  def view_template
    render Views::Layout.new(title: @user.display_name) do
      header(class: "mb-8") do
        h1(class: "text-2xl font-semibold") { @user.display_name }
        if @user.bio.present?
          p(class: "mt-2 max-w-2xl text-muted") { @user.bio }
        end
        if @user.website_url.present?
          p(class: "mt-2") do
            a(href: @user.website_url, target: "_blank", rel: "noopener") { @user.website_url }
          end
        end
      end

      h2(class: "mb-4 text-xl font-semibold") { @owner ? "Mes cartes" : "Cartes publiques" }

      if @maplines.any?
        div(class: "flex flex-col gap-3") do
          @maplines.each { |mapline| render_card(mapline) }
        end
      else
        p(class: "text-muted") { "Aucune carte publiée pour l'instant." }
      end
    end
  end

  private

  def render_card(mapline)
    div(class: "flex items-center justify-between gap-3 rounded-xl border border-line bg-surface p-5") do
      div(class: "min-w-0") do
        div(class: "flex items-center gap-2") do
          link_to mapline.title, public_mapline_path(mapline.slug),
            class: "text-lg font-semibold text-ink hover:no-underline hover:underline"
          render Components::StatusBadge.new(status: mapline.status) if @owner
        end
        if mapline.description.present?
          p(class: "mt-1 line-clamp-1 text-sm text-muted") { mapline.description }
        end
      end
      link_to "Ouvrir", public_mapline_path(mapline.slug), class: "btn btn-ghost text-sm"
    end
  end
end
