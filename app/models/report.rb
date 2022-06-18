class Report < ApplicationRecord
	belongs_to :product, optional: true    
end
