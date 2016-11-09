class AdminMailer < ActionMailer::Base
  default from: %{"VASKIT admin" <notice@vaskit.kr>},
          to: ['junsikahn@vaskit.kr', 'haksoon@vaskit.kr', 'seokkiyoon@vaskit.kr']

  def signup_submitted(user)
    @user = user
    mail(subject: "[VASKIT] 새로운 사용자가 회원가입하였습니다.")
  end

  def ask_submitted(ask, to)
    @ask = ask
    mail(to: to, subject: "[VASKIT] 새로운 질문이 작성되었습니다.")
  end

  def inquiry_submitted(inquiry)
    @inquiry = inquiry
    mail(subject: "[VASKIT] 문의가 접수되었습니다.")
  end

  def report_submitted(report)
    @report = report
    mail(subject: "[VASKIT] 신고가 접수되었습니다.")
  end

  def daily_summary
    user_summaries = User.find_by_sql(<<-SQL.squish)
      SELECT U.id AS 'user_id', U.email, U.string_id, U.name, date_format(addtime(U.created_at, '09:00:00'), '%Y-%m-%d') AS 'created_at', date_format(UV.recent_visit, '%Y-%m-%d') AS 'recent_visit',
        IFNULL(UV.visit_count, 0) AS 'visit_count',
        IFNULL(V.vote_count, 0) AS 'vote_count',
        IFNULL(C.comment_count, 0) AS 'comment_count',
        IFNULL(A.ask_count, 0) AS 'ask_count',
        IFNULL(CL.comment_like_count, 0) AS 'comment_like_count',
        IFNULL(AL.ask_like_count, 0) AS 'ask_like_count',
        IFNULL(SL.share_count, 0) AS 'share_count'
      FROM users U
        LEFT JOIN v_user_visits UV ON U.id = UV.user_id
        LEFT JOIN v_user_votes V ON U.id = V.user_id
        LEFT JOIN v_user_comments C ON U.id = C.user_id
        LEFT JOIN v_user_asks A ON U.id = A.user_id
        LEFT JOIN v_user_comment_likes CL ON U.id = CL.user_id
        LEFT JOIN v_user_ask_likes AL ON U.id = AL.user_id
        LEFT JOIN v_user_shares SL ON U.id = SL.user_id
      WHERE U.user_role = 'user'
      ORDER BY visit_count DESC
    SQL

    daily_summaries = Vote.find_by_sql(<<-SQL.squish)
      SELECT date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') AS date,
        IFNULL(SU.signup_count, 0) AS 'signup_count',
        IFNULL(AU.DAU, 0) AS 'DAU',
        IFNULL(UV.visit_count, 0) AS 'visit_count',
        IFNULL(V.vote_count, 0) AS 'vote_count',
        IFNULL(C.comment_count, 0) AS 'comment_count',
        IFNULL(A.ask_count, 0) AS 'ask_count',
        IFNULL(CL.comment_like_count, 0) AS 'comment_like_count',
        IFNULL(AL.ask_like_count, 0) AS 'ask_like_count',
        IFNULL(SL.share_count, 0) AS 'share_count'
      FROM `votes`
        LEFT JOIN v_daily_signups SU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = SU.date
        LEFT JOIN v_daily_active AU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = AU.date
        LEFT JOIN v_daily_visits UV ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = UV.date
        LEFT JOIN v_daily_votes V ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = V.date
        LEFT JOIN v_daily_comments C ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = C.date
        LEFT JOIN v_daily_asks A ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = A.date
        LEFT JOIN v_daily_comment_likes CL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = CL.date
        LEFT JOIN v_daily_ask_likes AL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = AL.date
        LEFT JOIN v_daily_shares SL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') = SL.date
      WHERE date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m-%d') BETWEEN ADDDATE(CURDATE(), INTERVAL -9 DAY) AND CURDATE()
      GROUP BY date ORDER BY date DESC
    SQL

    weekly_summaries = Vote.find_by_sql(<<-SQL.squish)
      SELECT date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') AS week,
      	IFNULL(SU.signup_count, 0) AS 'signup_count',
      	IFNULL(AU.WAU, 0) AS 'WAU',
      	IFNULL(UV.visit_count, 0) AS 'visit_count',
      	IFNULL(V.vote_count, 0) AS 'vote_count',
      	IFNULL(C.comment_count, 0) AS 'comment_count',
      	IFNULL(A.ask_count, 0) AS 'ask_count',
      	IFNULL(CL.comment_like_count, 0) AS 'comment_like_count',
      	IFNULL(AL.ask_like_count, 0) AS 'ask_like_count',
      	IFNULL(SL.share_count, 0) AS 'share_count'
      FROM `votes`
      	LEFT JOIN v_weekly_signups SU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = SU.week
      	LEFT JOIN v_weekly_active AU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = AU.week
      	LEFT JOIN v_weekly_visits UV ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = UV.week
      	LEFT JOIN v_weekly_votes V ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = V.week
      	LEFT JOIN v_weekly_comments C ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = C.week
      	LEFT JOIN v_weekly_asks A ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = A.week
      	LEFT JOIN v_weekly_comment_likes CL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = CL.week
      	LEFT JOIN v_weekly_ask_likes AL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = AL.week
      	LEFT JOIN v_weekly_shares SL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') = SL.week
      WHERE date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%u') BETWEEN date_format(ADDDATE(CURDATE(), INTERVAL -9 WEEK), '%Y-%u') AND date_format(CURDATE(), '%Y-%u')
      GROUP BY week ORDER BY week DESC
    SQL

    monthly_summaries = Vote.find_by_sql(<<-SQL.squish)
      SELECT date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') AS month,
      	IFNULL(SU.signup_count, 0) AS 'signup_count',
      	IFNULL(AU.MAU, 0) AS 'MAU',
      	IFNULL(UV.visit_count, 0) AS 'visit_count',
      	IFNULL(V.vote_count, 0) AS 'vote_count',
      	IFNULL(C.comment_count, 0) AS 'comment_count',
      	IFNULL(A.ask_count, 0) AS 'ask_count',
      	IFNULL(CL.comment_like_count, 0) AS 'comment_like_count',
      	IFNULL(AL.ask_like_count, 0) AS 'ask_like_count',
      	IFNULL(SL.share_count, 0) AS 'share_count'
      FROM `votes`
      	LEFT JOIN v_monthly_signups SU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = SU.month
      	LEFT JOIN v_monthly_active AU ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = AU.month
      	LEFT JOIN v_monthly_visits UV ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = UV.month
      	LEFT JOIN v_monthly_votes V ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = V.month
      	LEFT JOIN v_monthly_comments C ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = C.month
      	LEFT JOIN v_monthly_asks A ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = A.month
      	LEFT JOIN v_monthly_comment_likes CL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = CL.month
      	LEFT JOIN v_monthly_ask_likes AL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = AL.month
      	LEFT JOIN v_monthly_shares SL ON date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') = SL.month
      WHERE date_format(addtime(`votes`.created_at, '09:00:00'), '%Y-%m') BETWEEN date_format(ADDDATE(CURDATE(), INTERVAL -9 MONTH), '%Y-%m') AND date_format(CURDATE(), '%Y-%m')
      GROUP BY month ORDER BY month DESC
    SQL

    asks_summaries = Ask.find_by_sql(<<-SQL.squish)
      SELECT `asks`.id AS 'ask_id', `asks`.message, date_format(addtime(`asks`.created_at, '09:00:00'), '%Y-%m-%d') AS 'created_at',
      	IFNULL(V.vote_count, 0) AS 'vote_count',
      	IFNULL(C.comment_count, 0) AS 'comment_count',
      	IFNULL(CO.comment_others_count, 0) AS 'comment_others_count',
      	IFNULL(CM.comment_my_count, 0) AS 'comment_my_count',
      	IFNULL(AL.ask_like_count, 0) AS 'ask_like_count',
      	IFNULL(SL.share_count, 0) AS 'share_count'
      FROM `asks`
      	LEFT JOIN v_ask_votes V ON `asks`.id = V.ask_id
      	LEFT JOIN v_ask_comments C ON `asks`.id = C.ask_id
      	LEFT JOIN v_ask_comments_others CO ON `asks`.id = CO.ask_id
      	LEFT JOIN v_ask_comments_my CM ON `asks`.id = CM.ask_id
      	LEFT JOIN v_ask_likes AL ON `asks`.id = AL.ask_id
      	LEFT JOIN v_ask_shares SL ON `asks`.id = SL.ask_id
      	LEFT JOIN users U ON U.id = `asks`.user_id
      WHERE U.user_role = 'user'
      	AND date_format(addtime(`asks`.created_at, '09:00:00'), '%Y-%m-%d') BETWEEN ADDDATE(CURDATE(), INTERVAL -10 DAY) AND CURDATE()
      ORDER BY ask_id DESC
    SQL

    @total_visit_count = 0
    @total_vote_count = 0
    @total_comment_count = 0
    @total_ask_count = 0
    user_summaries.each do |u|
      @total_visit_count += u.visit_count
      @total_vote_count += u.vote_count
      @total_comment_count += u.comment_count
      @total_ask_count += u.ask_count
    end

    @user_top_10 = user_summaries[0..10]
    @daily_recent_10 = daily_summaries
    @weekly_recent_10 = weekly_summaries
    @monthly_recent_10 = monthly_summaries
    @asks_recent = asks_summaries

    date = Time.now - 3600  # 1시간 빼줌
    date = date.year.to_s + "년 "+ date.month.to_s + "월 " + date.day.to_s + "일"
    @date = date

    mail(subject: "[VASKIT] #{date} 일일 리포트").deliver
  end

  def client_error(log)
    @log = log
    mail(from: %{"Error notifier" <notice@vaskit.kr>}, to: 'junsikahn@vaskit.kr', subject: "[ERROR] #{log.error_message}")
  end

end
