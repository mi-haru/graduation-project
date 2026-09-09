# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

time_periods = [
  { name: "朝", position: 10 },
  { name: "昼", position: 20 },
  { name: "夕", position: 30 },
  { name: "就寝前", position: 40 }
]

time_periods.each do |attributes|
  time_period = TimePeriod.find_or_initialize_by(name: attributes[:name])
  time_period.update!(position: attributes[:position])
end
