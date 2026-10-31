/* =====================================================================
   SOCIAL MEDIA (IG CLONE) — STUDENT ANSWER TEMPLATE
   ===================================================================== */

USE ig_clone;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1.
-- Are there any tables with duplicate or missing null values? If so, how
-- would you handle them?

-- 1.Data cleaning for the table usesr-
-- Analysis to see the constraints and data types used for the columns

Describe users;
show create table users;

-- 2.Checking for any missing values/Null

Select * from users
where username or created_at is null or trim(username)= " ";
 -- not considering id column as its is primary key so it cant be null or duplicate
-- Conclusion = no missing  null values

-- 3.Duplicate check for user column
select username,count(*) as Duplicate_Count from users
group by username
having count(*)>1; 

-- Conclusion= No Duplicate Value
-- Structure Analysis for the photos table

select* from photos;
Describe photos;
show create table photos;

-- 1.Checking for missing null values in the photos table
Select * from photos 
where created_dat is null or user_id =" ";

-- Conclusion = no missing  null values

-- 3.Duplicate check for photos column
Select user_id, image_url, Count(*) as Duplicate_count
From photos
Group by  user_id, image_url
Having count(*) > 1;

-- Conclusion = no duplicate

-- 1 structural analysis for the table comments

Describe comments;
show create table comments;

-- 2 checking for missing null values for comments tables

select * from comments
where trim(comment_text)=' ' or created_at is null ;

-- Conclusion = no missing  null values

-- 3 Checking for duplicate values

select user_id,photo_id,comment_text,count(*) as Duplicate_count from comments
Group by user_id,photo_id,comment_text
having count(*)>1;

-- conclusion= no duplicate 

-- 1.structural analysis for likes table 
Describe likes;
show create table likes;

-- 2 checking for missing null values for comments tables

select * from  likes
where created_at is null; 

-- conclusion= no missing null values

-- 3 Checking for duplicate values

select user_id,photo_id,count(*) as occurrence_count from likes
group by user_id,photo_id
having count(*) >1; 

-- conclusion=no duplicate

-- 1.structural analysis for follows table 
Describe follows;
show create table follows;

-- 2 checking for missing null values for follows tables
select * from follows 
where follower_id=followee_id 
or created_at is null;

-- conclusion=no missing null values

-- 3 Checking for duplicate values

select follower_id,followee_id,count(*) as occurence_count from follows
group by follower_id,followee_id
having count(*)>1;

-- O2.
-- What is the distribution of user activity levels (e.g., number of posts,
-- likes, comments) across the user base?
select u.id AS user_id,u.username,
    (select count(*) from photos where user_id = u.id) as total_posts,
    (select count(*) from likes where user_id = u.id) as total_likes_given,
    (select count(*) from comments where user_id = u.id) as total_comments_made
from users u;

-- O3.
-- Calculate the average number of tags per post (photo_tags and photos
-- tables).
-- total number of  tags divided by total number of photos
select (select count(*) from photo_tags) / (select count(*) from photos ) as Average_Tags;

-- O4.
-- Identify the top users with the highest engagement rates (likes, comments)
-- on their posts and rank them.

create view user_post_engagement_stats as
with user_posts as
(
	select user_id, COUNT(*) as no_of_posts_uploaded
	from photos
	group by user_id
),
user_likes as
(
	select p.user_id, COUNT(*) as no_of_likes_gained
	from likes l
	join photos p on l.photo_id = p.id
	group by p.user_id
),
user_comments as
(
	select p.user_id, COUNT(*) as no_of_comments_gained
	from comments c
	join photos p on c.photo_id = p.id
	group by p.user_id
)
select
	u.id as user_id,
    u.username,
    coalesce (no_of_posts_uploaded, 0) as no_of_posts_uploaded,
    coalesce(no_of_likes_gained, 0) as no_of_likes_gained,
    coalesce(no_of_comments_gained, 0) as no_of_comments_gained,
    coalesce(no_of_likes_gained, 0) + coalesce(no_of_comments_gained, 0) as total_likes_and_comments_gained,
-- "Engagement Rate" is generally calculated by dividing the total interactions (likes and comments) by the total number of posts.
coalesce((coalesce(no_of_likes_gained, 0) + coalesce(no_of_comments_gained, 0)) * 1.0 / NULLIF(coalesce(no_of_posts_uploaded, 0), 0), 0) as engagement_rate
from users u
left join user_posts up on u.id = up.user_id
left join user_likes ul on u.id = ul.user_id
left join user_comments uc on u.id = uc.user_id;

-- Ranking users according to their engagement rates using the user_post_engagement_stats view.
select
	user_id, engagement_rate,
	rank()over(order by engagement_rate desc) as user_engagement_rank
from user_post_engagement_stats
order by user_engagement_rank, user_id;



-- O5.
-- Which users have the highest number of followers and followings?

create view user_follower_and_following as
select
	u.id as user_id,
    u.username,
    (select COUNT(*) from follows where followee_id = u.id) as no_of_followers,
    (select COUNT(*) from follows where follower_id = u.id) as no_of_followings
from users u
order by user_id;

-- Identifying users with the highest number of followers count, using the view 'user_follower_and_following'.
select user_id, username, no_of_followers
from
(
	select
		user_id, username, no_of_followers,
		rank()over(order by no_of_followers desc) as rnk
	FROM user_follower_and_following
) t
where rnk = 1
order by user_id;

-- Identifying users with the highest number of followings count, using the view 'user_follower_and_following'.
select user_id, username, no_of_followings
from
(
	select
		user_id, username, no_of_followings,
		rank()over(order by no_of_followings desc) as rnk
	from user_follower_and_following
) t
where rnk = 1
order by user_id;


-- O6.
-- Calculate the average engagement rate (likes, comments) per post for each
-- user.

-- Calculating user engagement rates using the user_post_engagement_stats view.

select user_id, username, engagement_rate
from user_post_engagement_stats;

-- O7.
-- Get the list of users who have never liked any post (users and likes
-- tables)

select
	u.id as user_id,
    username
from users u
where not exists(
	select 1
    from likes l
    where l.user_id = u.id
);




-- O8.
-- How can you leverage user-generated content (posts, hashtags, photo tags)
-- to create more personalized and engaging ad campaigns?

   select 
    u.id as user_id,
    u.username,
    t.tag_name,
    count(distinct pt.tag_id) as tag_usage,
    count(distinct l.photo_id) as total_likes_received,
    count(distinct c.id) as total_comments_received,
    (count(distinct l.photo_id) + count(distinct c.id)) as total_engagement
	from users u
	left Join photos p on u.id = p.user_id
	left Join photo_tags pt on p.id = pt.photo_id
	left Join tags t on pt.tag_id = t.id
	left Join likes l on p.id = l.photo_id 
	left Join comments c on p.id = c.photo_id
	group by u.id, u.username, t.tag_name
	order by total_engagement desc, tag_usage desc;

-- O9.
-- Are there any correlations between user activity levels and specific
-- content types (e.g., photos, videos, reels)? How can this information
-- guide content creation and curation strategies?

select 
u.id as user_id, 
u.username, 
count(distinct p.id) as total_photos, 
count(distinct l.photo_id) as total_likes, 
count(distinct c.id) as total_comments, 
ROUND( 
(count(distinct l.photo_id) + count(distinct c.id)) / 
count(distinct p.id), 
2 
) as avg_engagement_rate 
from users u 
left join photos p on u.id = p.user_id 
left join likes l on p.id = l.photo_id 
left join comments c on p.id = c.photo_id 
group by u.id, u.username 
having total_photos >=1
order by avg_engagement_rate desc;

-- O10.
-- Calculate the total number of likes, comments, and photo tags for each
-- user.
select  
u.id as user_id, 
u.username, 
count(distinct l.photo_id) as total_likes, 
count(distinct c.id) as total_comments, 
count(distinct pt.tag_id) as total_photo_tags 
FROM users u 
left join photos p on u.id = p.user_id 
left join likes l on p.id = l.photo_id 
left join comments c on p.id = c.photo_id 
left join photo_tags pt on p.id = pt.photo_id 
group by u.id, u.username 
order by total_likes desc, total_comments desc; 



-- O11.
-- Rank users based on their total engagement (likes, comments, shares) over a
-- month.

select  
u.id as user_id, 
u.username, 
count(distinct l.photo_id) as likes_given, 
count(distinct c.id) as comments_made, 
count(distinct l.photo_id) + count(distinct c.id) as 
total_engagement, 
rank() over (order by (count(distinct l.photo_id) + 
count(distinct c.id)) desc) as engagement_rank 
from users u 
left join photos p on u.id = p.user_id 
left join likes l on p.id = l.photo_id 
left join comments c on p.id = c.photo_id 
group by u.id, u.username 
order by total_engagement desc;


-- O12.
-- Retrieve the hashtags that have been used in posts with the highest average
-- number of likes. Use a CTE to calculate the average likes for each
-- hashtag first.


WITH hashtag_likes AS (
    SELECT
        t.id AS tag_id,
        t.tag_name,
        COUNT(l.photo_id) * 1.0
            / NULLIF(COUNT(DISTINCT pt.photo_id), 0)
            AS avg_likes_per_photo,
        COUNT(l.photo_id) AS total_likes,
        COUNT(DISTINCT pt.photo_id) AS total_photos
    FROM photo_tags pt
    JOIN tags t
        ON t.id = pt.tag_id
    LEFT JOIN likes l
        ON pt.photo_id = l.photo_id
    GROUP BY t.id, t.tag_name
)
SELECT
    tag_id,
    tag_name,
    avg_likes_per_photo,
    total_likes,
    total_photos
FROM hashtag_likes
ORDER BY avg_likes_per_photo DESC
LIMIT 10;
 
-- O13.
-- Retrieve the users who have started following someone after being followed
-- by that person.



SELECT DISTINCT
    u.id,
    u.username
FROM follows f1
JOIN follows f2
    ON f1.follower_id = f2.followee_id
    AND f1.followee_id = f2.follower_id
JOIN users u
    ON u.id = f2.follower_id;

/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1.
-- Based on user engagement and activity levels, which users would you
-- consider the most loyal or valuable? How would you reward or incentivize
-- these users?

SELECT  
u.id AS user_id, 
u.username, 
COUNT(DISTINCT p.id) AS total_posts, 
COUNT(DISTINCT l.photo_id) AS total_likes, 
COUNT(DISTINCT c.id) AS total_comments, 
(COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) AS 
engagement_score 
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id 
LEFT JOIN likes l ON p.id = l.photo_id 
LEFT JOIN comments c ON p.id = c.photo_id 
GROUP BY u.id, u.username 
ORDER BY engagement_score DESC 
LIMIT 10;

-- S2.
-- For inactive users, what strategies would you recommend to re-engage them
-- and encourage them to start posting or engaging again?

SELECT u.id, u.username 
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id 
LEFT JOIN likes l ON u.id = l.user_id 
WHERE p.id IS NULL AND l.photo_id IS NULL;

-- S3.
-- Which hashtags or content topics have the highest engagement rates? How can
-- this information guide content strategy and ad campaigns?

WITH hashtag_engagement AS ( 
  SELECT  
   t.tag_name, 
   AVG(like_count + comment_count) AS avg_engagement 
  FROM ( 
   SELECT  
    pt.tag_id, 
    COUNT(DISTINCT l.user_id) AS like_count, 
    COUNT(DISTINCT c.id) AS comment_count 
   FROM photo_tags pt 
   LEFT JOIN likes l ON pt.photo_id = l.photo_id 
   LEFT JOIN comments c ON pt.photo_id = c.photo_id 
   GROUP BY pt.tag_id 
  ) AS tag_summary 
  JOIN tags t ON t.id = tag_summary.tag_id 
  GROUP BY t.tag_name 
 ) 
 SELECT tag_name, avg_engagement 
 FROM hashtag_engagement 
 ORDER BY avg_engagement DESC 
 LIMIT 10;

-- S4.
-- Are there any patterns or trends in user engagement based on demographics
-- (age, location, gender) or posting times? How can these insights inform
-- targeted marketing campaigns?
SELECT  
HOUR(p.created_dat) AS posting_hour, 
COUNT(DISTINCT l.photo_id) AS total_likes, 
COUNT(DISTINCT c.id) AS total_comments 
FROM photos p 
LEFT JOIN likes l ON p.id = l.photo_id 
LEFT JOIN comments c ON p.id = c.photo_id 
GROUP BY posting_hour 
ORDER BY posting_hour; 


-- S5.
-- Based on follower counts and engagement rates, which users would be ideal
-- candidates for influencer marketing campaigns? How would you approach
-- and collaborate with these influencers?

WITH follower_counts AS (
    SELECT
        followee_id AS user_id,
        COUNT(DISTINCT follower_id) AS follower_count
    FROM follows
    GROUP BY followee_id
),
like_counts AS (
    SELECT
        p.user_id,
        COUNT(distinct l.photo_id) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT
        p.user_id,
        COUNT(c.id) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(fc.follower_count, 0) AS follower_count,
    COALESCE(lc.total_likes, 0) AS total_likes,
    COALESCE(cc.total_comments, 0) AS total_comments,
    COALESCE(lc.total_likes, 0)
        + COALESCE(cc.total_comments, 0) AS engagement_score
FROM users u
LEFT JOIN follower_counts fc ON u.id = fc.user_id
LEFT JOIN like_counts lc ON u.id = lc.user_id
LEFT JOIN comment_counts cc ON u.id = cc.user_id
ORDER BY follower_count DESC, engagement_score DESC
LIMIT 10;



-- S6.
-- Based on user behavior and engagement data, how would you segment the user
-- base for targeted marketing campaigns or personalized recommendations?

SELECT  
u.id AS user_id, 
u.username, 
COUNT(DISTINCT p.id) AS post_count, 
COUNT(DISTINCT l.photo_id) AS like_count, 
COUNT(DISTINCT c.id) AS comment_count, 
CASE 
WHEN COUNT(DISTINCT p.id) >= 10 AND COUNT(DISTINCT 
l.photo_id) >= 50 THEN 'Highly Active' 
WHEN COUNT(DISTINCT p.id) BETWEEN 5 AND 9 THEN 
'Moderately Active' 
ELSE 'Low Activity' 
END AS user_segment 
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id 
LEFT JOIN likes l ON u.id = l.user_id 
LEFT JOIN comments c ON u.id = c.user_id 
GROUP BY u.id, u.username 
ORDER BY user_segment; 

-- S7.
-- If data on ad campaigns (impressions, clicks, conversions) is available,
-- how would you measure their effectiveness and optimize future campaigns?

-- SQL is not required for this task, as it involves IF analysis and should be answered theoretically. A detailed explanation is already provided in the doc file.

-- S8.
-- How can you use user activity data to identify potential brand ambassadors
-- or advocates who could help promote Instagram's initiatives or events?


WITH follower_counts AS (
    SELECT
        followee_id AS user_id,
        COUNT(DISTINCT follower_id) AS follower_count
    FROM follows
    GROUP BY followee_id
),
like_counts AS (
    SELECT
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(fc.follower_count, 0) AS follower_count,
    COALESCE(lc.total_likes, 0) AS total_likes,
    COALESCE(cc.total_comments, 0) AS total_comments,
    COALESCE(lc.total_likes, 0)
        + COALESCE(cc.total_comments, 0) AS engagement_score
FROM users u
LEFT JOIN follower_counts fc
    ON u.id = fc.user_id
LEFT JOIN like_counts lc
    ON u.id = lc.user_id
LEFT JOIN comment_counts cc
    ON u.id = cc.user_id
ORDER BY engagement_score DESC, follower_count DESC
LIMIT 10;


-- S9.
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?

-- answered this question in the doc file

-- S10.
-- Assuming there's a "User_Interactions" table tracking user engagements, how
-- can you update the "Engagement_Type" column to change all instances of
-- "Like" to "Heart" to align with Instagram's terminology?

UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';


/* ===================================== END OF FILE ===================================== */
