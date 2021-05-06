--DDL

CREATE TABLE "users"
(
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) UNIQUE NOT NULL,
    last_login TIMESTAMP
);


CREATE TABLE "topics"
(
    id SERIAL PRIMARY KEY,
    topic VARCHAR(30) UNIQUE NOT NULL,
    description VARCHAR(500)
);


CREATE TABLE "posts"
(
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) UNIQUE NOT NULL,
    url VARCHAR(4000),
    content TEXT,
    user_id INTEGER NOT NULL,
    topic_id INTEGER,
    ts TIMESTAMP,
    CONSTRAINT fk_user FOREIGN KEY (user_id) 
      REFERENCES users ON DELETE     CASCADE,
    CONSTRAINT fk_topic FOREIGN KEY (topic_id) 
      REFERENCES topics ON DELETE SET NULL,
    CONSTRAINT fk_control
      CHECK ((url IS NOT NULL AND content IS NULL) OR
        (url IS NULL AND content IS NOT NULL))
);

CREATE TABLE "comments" (
  id SERIAL PRIMARY KEY,
  comment TEXT NOT NULL,
  post_id INTEGER NOT NULL,
  user_id INTEGER,
  comment_id INTEGER,
  ts TIMESTAMP,
  CONSTRAINT fk_post FOREIGN KEY (post_id) 
     REFERENCES posts ON DELETE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) 
     REFERENCES users ON DELETE SET NULL,
  CONSTRAINT fk_comment FOREIGN KEY (comment_id) 
     REFERENCES comments ON DELETE CASCADE
);



CREATE TABLE "votes" (
  id SERIAL PRIMARY KEY,
  vote INTEGER CONSTRAINT "vote" CHECK (vote = 1 OR vote = -1),
  post_id INTEGER NOT NULL,
  user_id INTEGER,
  CONSTRAINT "unique_vote" UNIQUE ("post_id", "user_id"),
  CONSTRAINT fk_post FOREIGN KEY (post_id) 
     REFERENCES posts ON DELETE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id)
     REFERENCES users ON DELETE SET NULL
);

CREATE INDEX "find_post_url" ON posts (url);
CREATE INDEX "direct_children" ON comments (comment_id);
CREATE INDEX "score" ON votes (post_id, vote);

--Migrations

INSERT INTO "topics" (topic) (SELECT DISTINCT topic FROM bad_posts);


WITH vote_users AS 
(
 SELECT REGEXP_SPLIT_TO_TABLE("upvotes", ',') as username
 FROM bad_posts
 UNION
 SELECT REGEXP_SPLIT_TO_TABLE("downvotes", ',') as username
 FROM bad_posts
 UNION
 SELECT username FROM bad_posts
 UNION
 SELECT username FROM bad_comments
)
INSERT INTO "users" (username) 
(
  SELECT DISTINCT username FROM vote_users
);


INSERT INTO "posts" (title, url, content, user_id, topic_id)
(
  SELECT SUBSTRING(b.title, 1, 100), b.url, b.text_content, u.id, t.id
  FROM bad_posts b
  JOIN users u 
  ON u.username = b.username
  JOIN topics t
  ON t.topic = b.topic
);

INSERT INTO "comments" (comment, post_id, user_id)
(
  SELECT b.text_content, p.id, u.id
  FROM bad_comments b
  JOIN posts p
  ON b.post_id = p.id	
  JOIN users u
  ON p.user_id = u.id
);

WITH vote_usernames AS (
	SELECT REGEXP_SPLIT_TO_TABLE("upvotes", ',') as vote_username,
	title,
	username
	FROM bad_posts
)
INSERT INTO "votes" (vote, post_id, user_id) 
(
  SELECT 1, p.id, u.id
  FROM users u
  JOIN vote_usernames v
  ON u.username = v.vote_username	
  JOIN posts p
  ON p.title = v.title
);

WITH vote_usernames AS (
	SELECT REGEXP_SPLIT_TO_TABLE("downvotes", ',') as vote_username,
	title,
	username
	FROM bad_posts
)
INSERT INTO "votes" (vote, post_id, user_id) 
(
  SELECT -1, p.id, u.id
  FROM users u
  JOIN vote_usernames v
  ON u.username = v.vote_username	
  JOIN posts p
  ON p.title = v.title
);