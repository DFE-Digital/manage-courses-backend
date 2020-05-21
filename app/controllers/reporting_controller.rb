class ReportingController < ActionController::API
  before_action :build_recruitment_cycle

  def reporting
    stats = {
      providers: ProviderReportingService.call(providers_scope: @recruitment_cycle.providers),
      courses: CourseReportingService.call(courses_scope: @recruitment_cycle.courses),
      publish: PublishReportingService.call(recruitment_cycle_scope: @recruitment_cycle),
    }

    render status: :ok, json: stats
  end

private

  def build_recruitment_cycle
    @recruitment_cycle = RecruitmentCycle.find_by(
      year: params[:recruitment_cycle_year],
    ) || RecruitmentCycle.current_recruitment_cycle
  end
end
