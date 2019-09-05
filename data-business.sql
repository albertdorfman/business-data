/* Find everytime that each user changes the screen to get into the canvas.. */

with 
  
  user_enter_canvas as (
      
      select    user_info.email,
                extract(date from timestamp_seconds(time_stamp)) AS date
      from      Mixpanel.events_log
      join      Mixpanel.user_info 
                on event_id = user_info.user_id
      where     event = 'change_screen' 
                and screen = 'canvas'  
                and Internalquestion_ is null 
                and user_info.email not like '%bonsai%'
      group by  email, date
  
  ),
  
  
#Figure out the first date that each user enters the app

  min_date_table as (
  
      select    email,
                min(date) as min_date
      from      user_enter_canvas
      group by  email

),


/* Join together all dates, that the user changed screen */

  dates_merged as (
  
      select    min_date_table.email,
                min_date,
                date,
                1 as place_holder
      from      user_enter_canvas
      join      min_date_table
                on user_enter_canvas.email = min_date_table.email
  
  ),


/*Figure out the year and week of each user's session, so that you can get a weekly cohort chart */

  weekly_cohorts as (
    
      select    email,
                min_date,
                extract(week from min_date) as week_cohort,
                date as session_date,
                date_add(min_date, interval 7 day) as one_week_boundary,
                date_add(min_date, interval 14 day) as two_week_boundary,
                date_add(min_date, interval 21 day) as three_week_boundary,
                date_add(min_date, interval 28 day) as four_week_boundary,
                date_add(min_date, interval 35 day) as five_week_boundary
      from      dates_merged
  ),
 
/* Get email, min_date, and week */
  
  ungrouped_weekly_cohort as( 
  
      select    email,
                min_date,
                week_cohort,
                case  when session_date < one_week_boundary then 0
                      when session_date >= one_week_boundary AND session_date < two_week_boundary then 1
                      when session_date >= two_week_boundary AND session_date < three_week_boundary then 2
                      when session_date >= three_week_boundary AND session_date < four_week_boundary then 3
                      when session_date >= four_week_boundary AND session_date < five_week_boundary then 4
                      else 5
                      end as week
      from      weekly_cohorts
      /*group by email and week so that if a user comes 2 times in week one, you only count that once*/
      group by  min_date,
                week_cohort,
                email,
                week
      order by  email, min_date asc, week asc
      ),
      
  weekly_cohorts_by_week as (
  
      select    week_cohort,
                week,
                count(*) as number_users
      from      ungrouped_weekly_cohort
      group by  week_cohort,
                week
                
       
      )
  select * from weekly_cohorts_by_week  
  order by week_cohort desc, week asc
