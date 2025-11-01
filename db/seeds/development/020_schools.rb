# frozen_string_literal: true
return if School.exists?

log('Create Schools...')

# Umieść pliki w: db/files/schools/sp53.png, db/files/schools/lo2.png
sp53_logo = Rails.root.join('db/files/schools/sp53.png')
lo2_logo  = Rails.root.join('db/files/schools/lo2.png')

@school_a = School.new(
  name:  'Szkoła Podstawowa nr 53 w Gdyni',
  slug:  'sp53-gdynia',
  city:  'Gdynia',
  country: 'PL'
)
@school_a.logo = uploaded_file(sp53_logo) if File.exist?(sp53_logo)
@school_a.save!

@school_b = School.new(
  name:  'LO nr 2 w Gdańsku',
  slug:  'lo2-gdansk',
  city:  'Gdańsk',
  country: 'PL'
)
@school_b.logo = uploaded_file(lo2_logo) if File.exist?(lo2_logo)
@school_b.save!
