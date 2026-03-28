# Refinements for human-readable size formatting.
# Use `using Mp3InfoLib::SizeUnits` in files that need these methods.
module Mp3InfoLib
  module SizeUnits
    refine Numeric do
      def kibibyte
        self * 1024
      end

      def mebibyte
        self * 1024 ** 2
      end

      def gibibyte
        self * 1024 ** 3
      end

      def tebibyte
        self * 1024 ** 4
      end

      def octet_units(fmt = '%.2f')
        case
        when self < 1.kibibyte
          "#{self} bytes"
        when self < 1.mebibyte
          "#{fmt % (to_f / 1.kibibyte)} KiB"
        when self < 1.gibibyte
          "#{fmt % (to_f / 1.mebibyte)} MiB"
        when self < 1.tebibyte
          "#{fmt % (to_f / 1.gibibyte)} GiB"
        else
          "#{fmt % (to_f / 1.tebibyte)} TiB"
        end
      end

      def kilobyte
        self * 1000
      end

      def megabyte
        self * 1000 ** 2
      end

      def gigabyte
        self * 1000 ** 3
      end

      def terabyte
        self * 1000 ** 4
      end

      def decimal_units(fmt = '%.2f')
        case
        when self < 1.kilobyte
          "#{self} bytes"
        when self < 1.megabyte
          "#{fmt % (to_f / 1.kilobyte)} KB"
        when self < 1.gigabyte
          "#{fmt % (to_f / 1.megabyte)} MB"
        when self < 1.terabyte
          "#{fmt % (to_f / 1.gigabyte)} GB"
        else
          "#{fmt % (to_f / 1.terabyte)} TB"
        end
      end
    end
  end
end
