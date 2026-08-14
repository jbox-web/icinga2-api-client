# frozen_string_literal: true

require_relative 'icinga2_types_snapshot'

# Regenerates data/icinga2_types.json from a live Icinga2 master.
#
# The gem ships a frozen snapshot rather than querying /v1/types at runtime:
# the public surface must not depend on which server happens to be contacted,
# and the test suite must run without one. Regenerating is therefore a manual,
# reviewable step whose diff shows exactly what an Icinga upgrade changed.
namespace :types do

  desc 'Regenerate data/icinga2_types.json from a live Icinga2 master (or from TYPES_JSON=<file>)'
  task :snapshot do
    catalogue = Icinga2TypesSnapshot.build(Icinga2TypesSnapshot.load_raw)
    path      = Icinga2TypesSnapshot.write(catalogue)

    puts "Wrote #{catalogue.size} types to #{path}"
  end

end
