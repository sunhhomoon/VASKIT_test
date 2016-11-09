# coding : utf-8
class AdminController < ApplicationController
  before_filter :auth_admin

  def index
    render :layout => "layout_admin"
  end


  def table
    @tables = ActiveRecord::Base.connection.tables
    @tables = @tables - ["schema_migrations",
                         "delayed_jobs",
                         "v_alba_ask_likes", "v_alba_asks", "v_alba_comment_likes", "v_alba_comments", "v_alba_shares", "v_alba_visits", "v_alba_votes",
                         "v_alba_daily_ask_likes", "v_alba_daily_asks", "v_alba_daily_comment_likes", "v_alba_daily_comments", "v_alba_daily_shares", "v_alba_daily_visits", "v_alba_daily_votes",
                         "v_user_ask_likes", "v_user_asks", "v_user_comment_likes", "v_user_comments", "v_user_shares", "v_user_visits", "v_user_votes",
                         "v_ask_comments", "v_ask_comments_my", "v_ask_comments_others", "v_ask_likes", "v_ask_shares", "v_ask_votes",
                         "v_daily_active", "v_daily_ask_likes", "v_daily_asks", "v_daily_comment_likes", "v_daily_comments", "v_daily_shares", "v_daily_signups", "v_daily_users", "v_daily_visits", "v_daily_votes",
                         "v_weekly_active", "v_weekly_ask_likes", "v_weekly_asks", "v_weekly_comment_likes", "v_weekly_comments", "v_weekly_shares", "v_weekly_signups", "v_weekly_users", "v_weekly_visits", "v_weekly_votes",
                         "v_monthly_active", "v_monthly_ask_likes", "v_monthly_asks", "v_monthly_comment_likes", "v_monthly_comments", "v_monthly_shares", "v_monthly_signups", "v_monthly_users", "v_monthly_visits", "v_monthly_votes",
                         "view_alba", "view_alba_daily", "view_ask_details", "view_asks", "view_daily", "view_monthly", "view_users", "view_weekly"]

    if params[:table_name]
      @tableModel = params[:table_name].classify.constantize
      @record_names = @tableModel.columns.map(&:name)
      @records = @tableModel.page(params[:page]).per(10).order("id desc")
      @record_count = @tableModel.all.count / 10 + 1
    end
    render :layout => "layout_admin"
  end

  def notice
    @notices = Notice.all.order("id desc")
    render :layout => "layout_admin"
  end

  def create_notice
    notice = Notice.create(:title => params[:title], :message => params[:message])
    User.where(:receive_notice_email => true).each do |user|
      UserMailer.delay.send_notice(user, notice)
    end
    render :json => {:status => "success"}
  end


  def rank_asks
    category_id = params[:category_id]
    if category_id
      @rank_asks = RankAsk.where(:category_id => category_id).order("ranking asc")
      if @rank_asks.blank?
        @asks = Ask.where(:category_id => category_id).page(0).per(5).order("id desc").limit(5)
      else
        @asks = Ask.where(:category_id => category_id).where("id not in (?)", @rank_asks.map(&:ask_id)).page(0).per(5).order("id desc").limit(5)
      end
      @category = Category.find(category_id)
    else
      @rank_asks = RankAsk.where(:category_id => nil).order("ranking asc")
      if @rank_asks.blank?
        @asks = Ask.all.page(0).per(5).order("id desc").limit(5)
      else
        @asks = Ask.where("id not in (?)", @rank_asks.map(&:ask_id)).page(0).per(5).order("id desc").limit(5)
      end
    end
    @categories = Category.all
    render :layout => "layout_admin"
  end

  def load_more_asks
    category_id = params[:category_id]
    if category_id == ""
      rank_asks = RankAsk.where(:category_id => nil).order("ranking asc")
      if rank_asks.blank?
        asks = Ask.all.page(params[:page]).per(5).order("id desc")
      else
        asks = Ask.where("id not in (?)", rank_asks.map(&:ask_id)).page(params[:page]).per(5).order("id desc")
      end
    else
      rank_asks = RankAsk.where(:category_id => category_id).order("ranking asc")
      if rank_asks.blank?
        asks = Ask.where(:category_id => category_id).page(params[:page]).per(5).order("id desc")
      else
        asks = Ask.where(:category_id => category_id).where("id not in (?)", rank_asks.map(&:ask_id)).page(params[:page]).per(5).order("id desc")
      end
    end
    asks = asks.as_json(:include => [:left_ask_deal, :right_ask_deal])
    render :json => {asks: asks}
  end

  def submit_rank_ask
    ask_id = params[:ask_id]
    ranking = params[:ranking]
    category_id = params[:category_id]
    category_id = nil if category_id.blank?
    ask = Ask.where(:id => ask_id)
    if ask.blank?
      status = "fail"
    else
      rank_ask = RankAsk.where(:ranking => ranking, :category_id => category_id).first
      if rank_ask
        rank_ask.update(:ask_id => ask_id)
      else
        RankAsk.create(:ask_id => ask_id, :ranking => ranking, :category_id => category_id)
      end
      status = "success"
    end
    render :json => {:status => status}
  end

  def delete_rank_ask
    RankAsk.find(params[:rank_ask_id]).destroy
    render :json => {:status => "success"}
  end


  def analysis
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
      	AND date_format(addtime(`asks`.created_at, '09:00:00'), '%Y-%m-%d') BETWEEN ADDDATE(CURDATE(), INTERVAL -9 DAY) AND CURDATE()
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

    render :layout => "layout_admin"
  end

end
