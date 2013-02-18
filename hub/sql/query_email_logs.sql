select count(*) from email_logs where user_id = (select id from users where  default_email = 'USER_EMAIL');
