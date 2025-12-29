# frozen_string_literal: true

class WebinarMailer < ApplicationMailer
  default from: 'AKAdemy 2.0 <bot@akademy.edu.pl>'

  def registration_confirmation(registration)
    @registration = registration
    @webinar_date = '29 grudnia 2025 (poniedziałek)'
    @webinar_time = '17:00 (GMT+1, Warszawa)'
    @zoom_link = 'https://polsl-pl.zoom.us/j/96258944674?pwd=V1TOSOBaFu1mAgahocUYlrzTno13TI.1'
    @zoom_meeting_id = '962 5894 4674'
    @zoom_passcode = '902114'
    @google_meet_link = 'https://meet.google.com/ihs-hqrj-uhv?hs=224'

    mail(
      to: @registration.email,
      subject: '🎓 Potwierdzenie rejestracji na webinar AKAdemy 2.0 – link do spotkania'
    )
  end
end
