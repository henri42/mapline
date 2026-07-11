# frozen_string_literal: true

# Frise chronologique navigable, partagée éditeur / lecteur.
#
# Piste horizontale à espacement uniforme (v1) : une graduation par date clé.
# Clic, glisser avec aimantation, flèches clavier et boutons préc./suiv.
# déplacent le curseur ; le panneau affiche le titre/description de la date
# courante. Les données de chaque date sont portées par les graduations
# (attributs `data-*`) — pas de blob JSON à échapper.
#
# À chaque changement, le contrôleur émet un évènement `timeline:change`
# (détail : sortKey, keyDateId, index) que la carte écoutera aux jalons suivants.
class Components::Timeline < Components::Base
  def initialize(key_dates:, id: "timeline")
    @key_dates = key_dates.to_a
    @id = id
  end

  def view_template
    return if @key_dates.empty?

    div(
      id: @id,
      class: "flex flex-col gap-5 rounded-2xl border border-line bg-surface p-6",
      data: { controller: "timeline", timeline_current_value: 0 },
      tabindex: "0"
    ) do
      render_panel
      render_track
    end
  end

  private

  # Panneau contextuel : date + titre + description de la graduation courante.
  def render_panel
    first = @key_dates.first

    div(class: "flex flex-col gap-1") do
      p(class: "text-sm font-semibold tracking-wide text-primary uppercase",
        data: { timeline_target: "date" }) { first.display_date }
      h3(class: "font-serif text-xl leading-tight",
        data: { timeline_target: "title" }) { first.title.to_s }
      p(class: "text-muted", data: { timeline_target: "description" }) { first.description.to_s }
    end
  end

  # Piste + graduations + curseur, encadrée par les boutons préc./suiv.
  def render_track
    div(class: "flex items-center gap-3") do
      button(type: "button", aria_label: "Date précédente",
        class: "shrink-0 #{button_classes(:ghost)} px-3",
        data: { action: "timeline#previous", timeline_target: "previous" }) { "‹" }

      div(
        class: "relative h-10 grow cursor-pointer select-none",
        data: {
          timeline_target: "track",
          action: "pointerdown->timeline#startDrag pointermove->timeline#drag pointerup->timeline#endDrag pointercancel->timeline#endDrag"
        }
      ) do
        # Rail
        div(class: "absolute top-1/2 right-0 left-0 h-0.5 -translate-y-1/2 rounded-full bg-line")

        # Graduations : une par date clé, chacune portant ses données.
        @key_dates.each_with_index do |key_date, index|
          button(
            type: "button",
            title: key_date.display_date,
            aria_label: key_date.display_date,
            class: "absolute top-1/2 h-3.5 w-3.5 -translate-x-1/2 -translate-y-1/2 " \
                   "rounded-full border-2 border-surface bg-muted transition-colors",
            data: {
              timeline_target: "tick",
              action: "timeline#selectTick",
              index: index,
              sort_key: key_date.sort_key,
              key_date_id: key_date.id,
              date: key_date.display_date,
              title: key_date.title.to_s,
              description: key_date.description.to_s
            }
          )
        end

        # Curseur
        div(
          class: "pointer-events-none absolute top-1/2 h-5 w-5 -translate-x-1/2 -translate-y-1/2 " \
                 "rounded-full border-2 border-white bg-primary shadow-md transition-[left] duration-200 ease-out",
          data: { timeline_target: "cursor" }
        )
      end

      button(type: "button", aria_label: "Date suivante",
        class: "shrink-0 #{button_classes(:ghost)} px-3",
        data: { action: "timeline#next", timeline_target: "next" }) { "›" }
    end
  end
end
