# This is a port of https://github.com/DFE-Digital/manage-courses-api/blob/master/src/ManageCourses.Api/Mapping/SubjectMapper.cs
class SubjectMapper
  @ucas_further_education = ["further education",
                             "higher education",
                             "post-compulsory"]

  @ucas_english = ["english",
                   "english language",
                   "english literature"]

  @ucas_mfl_welsh = %w[welsh]

  @ucas_design_and_tech = ["design and technology",
                           "design and technology (food)",
                           "design and technology (product design)",
                           "design and technology (systems and control)",
                           "design and technology (textiles)",
                           "engineering"]

  @ucas_classics = %w[ classics
                       latin]

  @ucas_direct_translation_secondary = ["art / art & design",
                                        "business education",
                                        "citizenship",
                                        "communication and media studies",
                                        "computer studies",
                                        "dance and performance",
                                        "drama and theatre studies",
                                        "economics",
                                        "geography",
                                        "health and social care",
                                        "history",
                                        "music",
                                        "outdoor activities",
                                        "physical education",
                                        "psychology",
                                        "religious education",
                                        "social science"]

  @ucas_primary = ["early years",
                   "upper primary",
                   "primary",
                   "lower primary"]

  @ucas_mathematics = ["mathematics",
                       "mathematics (abridged)"]

  @ucas_physics = ["physics",
                   "physics (abridged)"]

  @ucas_unexpected = [
    "construction and the built environment",
    # "history of art",
    "home economics",
    "hospitality and catering",
    "personal and social education",
    # "philosophy",
    "sport and leisure",
    "environmental science",
    "law",
  ]

  @ucas_rename = {
    "chinese" => "mandarin",
    "art / art & design" => "art and design",
    "business education" => "business studies",
    "computer studies" => "computing",
    "science" => "balanced science",
    "dance and performance" => "dance",
    "drama and theatre studies" => "drama",
    "social science" => "social sciences"
  }

  @ucas_needs_mention_in_title = {
    "humanities" => /humanities/,
    "science" => /(?<!social |computer )science/,
    "modern studies" => /modern studies/,
  }

  MAPPINGS = {
    primary: {
      ["english", "english language", "english literature"] => "Primary with English",
      %w[geography history] => "Primary with geography and history",
      ["mathematics", "mathematics (abridged)"] => "Primary with mathematics",
      ["languages",
       "languages (african)",
       "languages (asian)",
       "languages (european)",
       "english as a second or other language",
       "french",
       "german",
       "italian",
       "japanese",
       "russian",
       "spanish",
       "arabic",
       "bengali",
       "gaelic",
       "greek",
       "hebrew",
       "urdu",
       "mandarin",
       "punjabi"] => "Primary with modern languages",
      ["science", "physics", "physics (abridged)", "biology", "chemistry"] => "Primary with science",
      ["physical education"] => "Primary with physical education",
    },
    secondary: {
      ["mathematics", "mathematics (abridged)"] => "Mathematics",
      ["physics", "physics (abridged)"] => "Physics",
      ["design and technology",
       "design and technology (food)",
       "design and technology (product design)",
       "design and technology (systems and control)",
       "design and technology (textiles)",
       "engineering"] => "Design and technology",
       %w[classics latin] => "Classics",
       %w[chinese mandarin] => "Mandarin",
       ["english as a second or other language"] => "English as a second or other language",
       %w[french] => "French",
       %w[german] => "German",
       %w[italian] => "Italian",
       %w[japanese] => "Japanese",
       %w[russian] => "Russian",
       %w[spanish] => "Spanish",
       %w[biology] => "Biology",
       %w[chemistry] => "Chemistry",
    },
  }.freeze

  def self.is_further_education(subjects)
    subjects = subjects.map { |subject| (subject.strip! || subject).downcase }
    (subjects & @ucas_further_education).any?
  end

  def self.map_to_subject_name(ucas_subject)
    res = (@ucas_rename[ucas_subject] || ucas_subject).capitalize

    (res.sub "english", "English" || res)
  end

  class GroupedSubjectMapping
    def initialize(included_ucas_subjects, resulting_dfe_subject)
      @included_ucas_subjects = included_ucas_subjects
      @resulting_dfe_subject = resulting_dfe_subject
    end

    def applicable_to?(ucas_subjects_to_map)
      (ucas_subjects_to_map & @included_ucas_subjects).any?
    end

    def to_s
      @resulting_dfe_subject
    end
  end

  def self.map_to_secondary_subjects(course_title, ucas_subjects)
    secondary_subject_mappings = MAPPINGS[:secondary].map do |ucas_input_subjects, dfe_subject|
      GroupedSubjectMapping.new(ucas_input_subjects, dfe_subject)
    end

    secondary_subjects = []

    secondary_subjects += secondary_subject_mappings.map { |mapping|
      mapping.to_s if mapping.applicable_to?(ucas_subjects)
    }.compact

    ucas_language_cat = ["languages",
                         "languages (african)",
                         "languages (asian)",
                         "languages (european)"]

    ucas_mfl_mandarin = %w[chinese mandarin]

    ucas_mfl_main = ["english as a second or other language",
                     "french",
                     "german",
                     "italian",
                     "japanese",
                     "russian",
                     "spanish"]

      #  Does the subject list mention languages but hasn't already been covered?
    if (ucas_subjects & ucas_language_cat).any? && (ucas_subjects & ucas_mfl_mandarin).none? && (ucas_subjects & ucas_mfl_main).none?
      secondary_subjects.push("Modern languages (other)")
    end

      # Does the subject list mention a subject we are happy to translate directly?
    (ucas_subjects & @ucas_direct_translation_secondary).each do |ucas_subject|
      secondary_subjects.push(map_to_subject_name(ucas_subject))
    end
      # Does the subject list mention a subject we are happy to translate if the course title contains a mention?
    (ucas_subjects & @ucas_needs_mention_in_title.keys).each do |ucas_subject|
      if course_title.match?(@ucas_needs_mention_in_title[ucas_subject])
        secondary_subjects.push(map_to_subject_name(ucas_subject))
      end
    end

      # Does the subject list mention english, and it's mentioned in the title (or it's the only subject we know for this course)?
    if (ucas_subjects & @ucas_english).any?
      if secondary_subjects.none? || course_title.index("english") != nil
        secondary_subjects.push("English")
      end
    end

      # if nothing else yet, try welsh
    if secondary_subjects.none? && (ucas_subjects & @ucas_mfl_welsh).any?
      secondary_subjects.push("Welsh")
    end

    secondary_subjects
  end


        # /// <summary>
        # /// This maps a list of of UCAS subjects to our interpretation of subjects.
        # /// UCAS subjects are a pretty loose tagging system where individual tags don't always
        # /// represent the subjects you will be able to teach but also categories (such as "secundary", "foreign languages" etc)
        # /// there is also duplication ("chinese" vs "mandarin") and ambiguity
        # /// (does "science" = Balanced science, a category, or Primary with science?)
        # ///
        # /// This takes this list of tags and the course title and applies heuristics to determine
        # /// which subjects you will be allowed to teach when you graduate, making the subjects more suitable for searching.
        # /// </summary>
        # /// <param name="course_title">The name of the course</param>
        # /// <param name="ucas_subjects">The subject tags from UCAS</param>
        # /// <returns>An enumerable of all the subjects the course should be findable by.</returns>


  def self.map_to_primary_subjects(ucas_subjects)
    primary_subject_mappings = MAPPINGS[:primary].map do |ucas_input_subjects, dfe_subject|
      GroupedSubjectMapping.new(ucas_input_subjects, dfe_subject)
    end

    %w[Primary] + primary_subject_mappings.map { |mapping|
      mapping.to_s if mapping.applicable_to?(ucas_subjects)
    }.compact
  end

  def self.get_subject_list(course_title, ucas_subjects)
    ucas_subjects = ucas_subjects.map { |subject| (subject.strip! || subject).downcase }
    course_title = (course_title.strip! || course_title).downcase
    # if unexpected throw.
    if (ucas_subjects & @ucas_unexpected).any?
      raise "found unsupported subject name(s): #{(ucas_subjects & @ucas_unexpected) * ', '}"
    # If the subject indicates that it's primary, do not associate it with any
    # Secondary subjects (that happens a lot in UCAS data). Instead, mark it as primary
    # and additionally test for specialisations (e.g. Pimary with mathematics)
    # note a course can cover multiple specialisations, e.g. Primary with geography and Primary with history
    elsif (ucas_subjects & @ucas_primary).any?
      return map_to_primary_subjects(ucas_subjects)
    # If the subject indicates that it's in the Further Education space,
    # just assign Further education to it and do not associate it with any
    # secondary subjects
    elsif (ucas_subjects & @ucas_further_education).any?
      return ["Further education"]
    # The most common case is when the course is teaching secondary subjects.
    else
      return map_to_secondary_subjects(course_title, ucas_subjects)
    end
  end
end
