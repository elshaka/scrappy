require 'watir'
require 'csv'

PRODUCT_URL = 'https://www.amazon.ca/dp/B09DC2GJNW'

puts 'Starting web browser...'
browser = Watir::Browser.new

puts 'Opening product page...'
browser.goto PRODUCT_URL
reviews_link = browser.a(data_hook: 'see-all-reviews-link-foot')
reviews_link.wait_until(&:exists?)
reviews_link.click

puts 'Opening product reviews page...'
reviews = []
loop do
  browser.div(class: 'reviews-loading aok-hidden').wait_until(&:exists?)

  puts 'Parsing reviews...'
  browser.div(class: 'review-views').children(class: 'review').each do |review|
    # TODO Fix this behavior
    next unless review.exists?

    reviews << {
      author: review.span(class: 'a-profile-name').text,
      title: review.a(class: 'review-title').text,
      content: review.span(class: 'review-text').text,
      rating: review.i(class: 'review-rating').text_content.to_i
    }
  end

  next_button = browser.li(class: 'a-last').a
  break unless next_button.exists?
  puts 'Loading next page...'
  next_button.click
end

puts 'Saving reviews to csv file...'
CSV.open('reviews.csv', 'wb', write_headers: true, headers: reviews.first.keys) do |csv|
  reviews.each { |review| csv << review }
end
