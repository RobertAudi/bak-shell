module BakShell
  class BaseError < ArgumentError; end
  class TargetMissingError  < BaseError; end
  class TooManyTargetsError < BaseError; end
  class InvalidTargetError  < BaseError; end
  class InvalidBackupError  < BaseError; end
  class InvalidOptionError  < BaseError; end
end
