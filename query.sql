create table wikiedits (
    id BIGINT,
    type TEXT,
    namespace INT,
    title TEXT,
    title_url TEXT,
    comment TEXT,
    timestamp TIMESTAMP,
    user TEXT,
    bot BOOLEAN,
    notify_url TEXT,
    minor BOOLEAN,
    length JSON,
    revision JSON,
    server_url TEXT,
    server_name TEXT,
    server_script_path TEXT,
    wiki TEXT,
    parsedcomment TEXT
) with (
    connector = 'sse',
    endpoint = 'https://stream.wikimedia.org/v2/stream/recentchange',
    format = 'json'
);

create table top_editors (
    time TIMESTAMP,
    user TEXT,
    bot BOOLEAN,
    count INT,
    diff INT,
    position TEXT NOT NULL
) with (
    connector = 'redis',
    type = 'sink',
    format = 'json',
    'address' = 'redis://fly-arroyo-fly-redis.upstash.io:6379',
    username = 'default',
    password = '{{ REDIS_PASSWORD }}',
    target = 'hash',
    'target.key_prefix' = 'top_editors',
    'target.field_column' = 'position'
);

insert into top_editors
select window.end as time, "user", bot, count, diff, cast(row_num as TEXT) from (
    select *, ROW_NUMBER() over (
        partition by window
        order by count desc
    ) as row_num
        from (
            select count(*) as count, 
                "user", 
                sum(coalesce(cast(extract_json(length, '$.new')[1] as int), 0) - coalesce(cast(extract_json(length, '$.old')[1] as int), 0)) as diff, 
                bot, 
                hop(interval '5 second', interval '1 minute') as window
            from  wikiedits
            group by "user", bot, window)
) where row_num <= 10;
