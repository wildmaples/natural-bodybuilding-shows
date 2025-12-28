module EventsHelper
  def federation_badge_classes(federation, past = false)
    base_classes = if past
      "border"
    else
      "border"
    end

    case federation
    when "OCB"
      if past
        "#{base_classes} bg-blue-500/10 text-blue-400/70 border-blue-500/30"
      else
        "#{base_classes} bg-blue-500/20 text-blue-400 border-blue-500/40"
      end
    when "WNBF"
      if past
        "#{base_classes} bg-orange-500/10 text-orange-400/70 border-orange-500/30"
      else
        "#{base_classes} bg-orange-500/20 text-orange-400 border-orange-500/40"
      end
    else
      "#{base_classes} bg-slate-500/20 text-slate-400 border-slate-500/40"
    end
  end
end
