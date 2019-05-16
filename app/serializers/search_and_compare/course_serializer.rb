module SearchAndCompare
  class CourseSerializer
    # ucasProviderData = ucasProviderData ?? new Domain.Models.Provider();
    # ucasCourseData = ucasCourseData ?? new Domain.Models.Course();
    # var sites = ucasCourseData.CourseSites ?? new ObservableCollection<CourseSite>();
    # providerEnrichmentModel = providerEnrichmentModel ?? new ProviderEnrichmentModel();
    # courseEnrichmentModel = courseEnrichmentModel ?? new CourseEnrichmentModel();

    # var useUcasContact =
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Email) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Website) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Address1) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Address2) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Address3) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Address4) &&
    #     string.IsNullOrWhiteSpace(providerEnrichmentModel.Postcode);
    #
    # var subjectStrings = ucasCourseData?.CourseSubjects != null
    #     ? subjectMapper.GetSubjectList(ucasCourseData.Name, ucasCourseData.CourseSubjects.Select(x => x.Subject.SubjectName))
    #     : new List<string>();
    #
    # var subjects = new Collection<SearchAndCompare.Domain.Models.Joins.CourseSubject>(subjectStrings.Select(subject =>
    #     new SearchAndCompare.Domain.Models.Joins.CourseSubject
    #     {
    #         Subject = new SearchAndCompare.Domain.Models.Subject
    #         {
    #             Name = subject
    #         }
    #     }).ToList());
    # var isFurtherEducation = subjects.Any(c =>
    #     c.Subject.Name.Equals("Further education", StringComparison.InvariantCultureIgnoreCase));
    #
    # var provider = new SearchAndCompare.Domain.Models.Provider
    # {
    #     Name = ucasProviderData.ProviderName,
    #     ProviderCode = ucasProviderData.ProviderCode
    # };
    #
    # var accreditingProvider = ucasCourseData.AccreditingProvider == null ? null :
    #     new SearchAndCompare.Domain.Models.Provider
    #     {
    #         Name = ucasCourseData.AccreditingProvider.ProviderName,
    #         ProviderCode = ucasCourseData.AccreditingProvider.ProviderCode
    #     };
    #
    # var routeName = ucasCourseData.Route;
    # var isSalaried = string.Equals(ucasCourseData?.ProgramType, "ss", StringComparison.InvariantCultureIgnoreCase)
    #               || string.Equals(ucasCourseData?.ProgramType, "ta", StringComparison.InvariantCultureIgnoreCase);
    # var fees = courseEnrichmentModel.FeeUkEu.HasValue ? new Fees
    # {
    #     Uk = (int)(courseEnrichmentModel.FeeUkEu ?? 0),
    #     Eu = (int)(courseEnrichmentModel.FeeUkEu ?? 0),
    #     International = (int)(courseEnrichmentModel.FeeInternational ?? 0),
    # } : new Fees();
    #
    # var address = useUcasContact ? MapAddress(ucasProviderData) : MapAddress(providerEnrichmentModel);
    # var mappedCourse = new SearchAndCompare.Domain.Models.Course
    # {
    #     ProviderLocation = new Location { Address = address },
    #     Duration = MapCourseLength(courseEnrichmentModel.CourseLength),
    #     StartDate = ucasCourseData.StartDate,
    #     Name = ucasCourseData.Name,
    #     ProgrammeCode = ucasCourseData.CourseCode,
    #     Provider = provider,
    #     AccreditingProvider = accreditingProvider,
    #     IsSen = ucasCourseData.IsSen,
    #     Route = new Route
    #     {
    #         Name = routeName,
    #         IsSalaried = isSalaried
    #     },
    #     IncludesPgce = MapQualification(ucasCourseData.Qualification),
    #     HasVacancies = ucasCourseData.HasVacancies,
    #     Campuses = new Collection<SearchAndCompare.Domain.Models.Campus>(sites
    #         .Where(school => String.Equals(school.Status, "r", StringComparison.InvariantCultureIgnoreCase) && String.Equals(school.Publish, "y", StringComparison.InvariantCultureIgnoreCase))
    #         .Select(school =>
    #             new SearchAndCompare.Domain.Models.Campus
    #             {
    #                 Name = school.Site.LocationName,
    #                 CampusCode = school.Site.Code,
    #                 Location = new Location
    #                 {
    #                     Address = MapAddress(school.Site)
    #                 },
    #                 VacStatus = school.VacStatus
    #             }
    #         ).ToList()),
    #     CourseSubjects = subjects,
    #     Fees = fees,

    #     IsSalaried = isSalaried,

    #     ContactDetails = new Contact
    #     {
    #         Phone = useUcasContact ? ucasProviderData.Telephone : providerEnrichmentModel.Telephone,
    #         Email = useUcasContact ? ucasProviderData.Email : providerEnrichmentModel.Email,
    #         Website = useUcasContact ? ucasProviderData.Url : providerEnrichmentModel.Website,
    #         Address = address
    #     },

    #     ApplicationsAcceptedFrom = sites.Select(x => x.ApplicationsAcceptedFrom).Where(x => x.HasValue)
    #         .OrderBy(x => x.Value)
    #         .FirstOrDefault(),
    #
    #     FullTime = ucasCourseData.StudyMode == "P" ? VacancyStatus.NA : VacancyStatus.Vacancies,
    #     PartTime = ucasCourseData.StudyMode == "F" ? VacancyStatus.NA : VacancyStatus.Vacancies,
    #
    #     Mod = ucasCourseData.TypeDescription,
    # };

    # mappedCourse.DescriptionSections = new Collection<CourseDescriptionSection>();

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     //TODO move the CourseDetailsSections constants into SearchAndCompare.Domain.Models
    #     // but this will work ftm
    #     Name = "about this training programme",//CourseDetailsSections.AboutTheCourse,
    #     Text = courseEnrichmentModel.AboutCourse
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "interview process",//CourseDetailsSections.InterviewProcess,
    #     Text = courseEnrichmentModel.InterviewProcess
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "about fees",//CourseDetailsSections.AboutFees,
    #     Text = courseEnrichmentModel.FeeDetails
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "about salary",//CourseDetailsSections.AboutSalary,
    #     Text = courseEnrichmentModel.SalaryDetails
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "entry requirements",//CourseDetailsSections.EntryRequirementsQualifications,
    #     Text = courseEnrichmentModel.Qualifications
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "entry requirements personal qualities",//CourseDetailsSections.EntryRequirementsPersonalQualities,
    #     Text = courseEnrichmentModel.PersonalQualities
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "entry requirements other",//CourseDetailsSections.EntryRequirementsOther,
    #     Text = courseEnrichmentModel.OtherRequirements
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "financial support",//CourseDetailsSections.FinancialSupport,
    #     Text = courseEnrichmentModel.FinancialSupport
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "about school placements",//CourseDetailsSections.AboutSchools,
    #     Text = courseEnrichmentModel.HowSchoolPlacementsWork
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "about this training provider",//CourseDetailsSections.AboutTheProvider,
    #     Text = providerEnrichmentModel.TrainWithUs
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "about this training provider accrediting",//CourseDetailsSections.AboutTheAccreditingProvider,
    #     Text = GetAccreditingProviderEnrichment(ucasCourseData?.AccreditingProvider?.ProviderCode, providerEnrichmentModel)
    # });

    # mappedCourse.DescriptionSections.Add(new CourseDescriptionSection
    # {
    #     Name = "training with disabilities",//CourseDetailsSections.TrainWithDisabilities,
    #     Text = providerEnrichmentModel.TrainWithDisability
    # });

  end
end
