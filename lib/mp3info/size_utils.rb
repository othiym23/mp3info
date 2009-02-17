class Numeric
  def kibibyte
    self * 1024
  end
  
  def mebibyte
    self * 1.kibibyte ** 2
  end
  
  def gibibyte
    self * 1.kibibyte ** 3
  end
  
  def tebibyte
    self * 1.kibibyte ** 4
  end

  def octet_units(fmt='%.2f')
    case
    when self < 1.kibibyte
      "#{self} bytes"
    when self < 1.mebibyte
      "#{fmt % (self.to_f / 1.kibibyte)} KiB"
    when self < 1.gibibyte
      "#{fmt % (self.to_f / 1.mebibyte)} MiB"
    when self < 1.tebibyte
      "#{fmt % (self.to_f / 1.gibibyte)} GiB"
    else
      "#{fmt % (self.to_f / 1.tebibyte)} TiB"
    end
  end

  def kilobyte
    self * 1000
  end
  
  def megabyte
    self * 1.kilobyte ** 2
  end
  
  def gigabyte
    self * 1.kilobyte ** 3
  end
  
  def terabyte
    self * 1.kilobyte ** 4
  end

  def decimal_units(fmt='%.2f')
    case
    when self < 1.kilobyte
      "#{self} bytes"
    when self < 1.megabyte
      "#{fmt % (self.to_f / 1.kilobyte)} KB"
    when self < 1.gigabyte
      "#{fmt % (self.to_f / 1.megabyte)} MB"
    when self < 1.terabyte
      "#{fmt % (self.to_f / 1.gigabyte)} GB"
    else
      "#{fmt % (self.to_f / 1.terabyte)} TB"
    end
  end
end
