# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

now = Time.zone.now
(1..40).each do |index|
  created_at = now.ago(index.days)
  updated_at = now.ago(index.days)

  hour_ago = rand(0..23)
  created_at = created_at.ago(hour_ago.hours)
  updated_at = created_at.ago(hour_ago.hours)

  availability = rand(0..1)
  
  ProductTrack.create(
    rakuten_item_code: "hakomeda:10000009",
    price: 3000,
    availability: availability,
    review_count: 30,
    review_average: 4.1,
    created_at: created_at,
    updated_at: updated_at
  )

end