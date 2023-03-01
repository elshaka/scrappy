require 'watir'
require 'csv'

BASE_PRODUCT_URL = 'https://www.amazon.com/dp/'

REVIEW_PARSERS = {
  author: ->(review) { review.span(class: 'a-profile-name').text },
  title: ->(review) { review.a(class: 'review-title').text },
  content: ->(review) { review.span(class: 'review-text').text },
  rating: ->(review) { review.i(class: 'review-rating').text_content.to_i }
}

asin = ARGV[0]
product_url = BASE_PRODUCT_URL + asin
timestamp = Time.now.strftime('%Y%m%d%H%M%S')
csv_filename = "#{asin}-#{timestamp}.csv"

puts 'Starting web browser...'
browser = Watir::Browser.new :chrome
 
puts 'Opening product page...'
browser.goto product_url
reviews_link = browser.a(data_hook: 'see-all-reviews-link-foot')
reviews_link.wait_until(&:exists?)
reviews_link.click
 
puts 'Opening product reviews page...'
reviews = []

begin
  loop do
    browser.div(class: 'reviews-loading aok-hidden').wait_until(&:exists?)

    puts 'Parsing reviews...'
    browser.div(class: 'review-views').children(class: 'review').each do |review_html|
      # TODO Fix this behavior
      next unless review_html.exists?

      reviews << REVIEW_PARSERS.each_with_object({}) do |(field, parser), review|
        review[field] = parser.call(review_html)
      end
    end

    next_button = browser.li(class: 'a-last').a
    break unless next_button.exists?
    puts 'Loading next page...'
    next_button.click
  end
rescue StandardError => e
  warn "An error ocurred while parsing the page #{browser.url}"
  warn "\t#{e.message}"
ensure
  unless reviews.empty?
    puts 'Saving reviews to csv file...'
    CSV.open(csv_filename, 'wb', write_headers: true, headers: REVIEW_PARSERS.keys) do |csv|
      reviews.each { |review| csv << review }
    end
  end
end
