module RoutingFilter
  class RefineryLocales < Filter

    @@include_default_locale = true
    cattr_writer :include_default_locale

    class << self
      def include_default_locale?
        @@include_default_locale
      end

      def locales
        @@locales ||= I18n.available_locales.map(&:to_sym)
      end

      def locales=(locales)
        @@locales = locales.map(&:to_sym)
      end

      def locales_pattern
        @@locales_pattern ||= %r(^/(#{self.locales.map { |l| Regexp.escape(l.to_s) }.join('|')})(?=/|$))
      end
    end

    def around_recognize(path, env, &block)
       locale = extract_segment!(self.class.locales_pattern, path) # remove the locale from the beginning of the path
      yield.tap do |params|                                       # invoke the given block (calls more filters and finally routing)
        params[:locale] = locale if locale                        # set recognized locale to the resulting params hash
      end
    end

    def around_generate(params, &block)
      locale = params.delete(:locale) || ::I18n.locale

      yield.tap do |result|
        result = result.is_a?(Array) ? result.first : result
        if ::Refinery::I18n.url_filter_enabled? and
           locale != ::Refinery::I18n.default_frontend_locale and
           result !~ %r{^/(refinery|wymiframe)}
          result.sub!(%r(^(http.?://[^/]*)?(.*))) { "#{$1}/#{locale}#{$2}" }
        end
      end
    end

  end
end
