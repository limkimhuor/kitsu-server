module Media
  extend ActiveSupport::Concern

  included do
    include Titleable
    include Rateable
    include Rankable
    include Trendable
    include WithCoverImage
    include Sluggable

    friendly_id :slug_candidates, use: %i[slugged finders history]
    resourcify
    has_attached_file :poster_image, styles: {
      tiny: ['110x156#', :jpg],
      small: ['284x402#', :jpg],
      medium: ['390x554#', :jpg],
      large: ['550x780#', :jpg]
    }, convert_options: {
      tiny: '-quality 90 -strip',
      small: '-quality 75 -strip',
      medium: '-quality 70 -strip',
      large: '-quality 60 -strip'
    }

    update_index("media##{name.underscore}") { self }

    has_and_belongs_to_many :genres
    has_many :castings, as: 'media'
    has_many :installments, as: 'media'
    has_many :franchises, through: :installments
    has_many :library_entries, as: 'media', dependent: :destroy,
                               inverse_of: :media
    has_many :mappings, as: 'media', dependent: :destroy
    has_many :reviews, as: 'media', dependent: :destroy
    has_many :media_relationships, as: 'source', dependent: :destroy
    has_many :inverse_media_relationships, as: 'destination',
                                           class_name: 'MediaRelationship',
                                           dependent: :destroy
    has_many :favorites, as: 'item', dependent: :destroy,
                         inverse_of: :item
    delegate :year, to: :start_date, allow_nil: true

    validates_attachment :poster_image, content_type: {
      content_type: %w[image/jpg image/jpeg image/png image/gif]
    }

    after_create :follow_self
  end

  def slug_candidates
    [
      -> { canonical_title },
      -> { titles[:en_jp] }
    ]
  end

  # How long the series ran for, or nil if the start date is unknown
  def run_length
    (end_date || Date.today) - start_date if start_date
  end

  def feed
    @feed ||= Feed.media(self.class.name, id)
  end

  def aggregated_feed
    @aggregated_feed ||= Feed.media_aggr(self.class.name, id)
  end

  def follow_self
    aggregated_feed.follow(feed)
  end
end
