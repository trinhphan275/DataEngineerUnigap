#!/bin/bash

# Download the dataset
# curl -O https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv tmdb-movies.csv

awk -v RS='"' 'NR%2==0{gsub(/\n/, "")}1' ORS='"' tmdb-movies.csv > tmdb-movies-transformed-1.csv

echo Xoa newline

awk 'BEGIN{FS=OFS="\""} {for(i=2;i<=NF;i+=2)gsub(/,/," ",$i)}1' tmdb-movies-transformed-1.csv > tmdb-movies-transformed.csv

echo hoan thanh xu li cac ki tu khong can thiet 

awk 'BEGIN {FS=OFS=","} {
    if (NR > 1) {  # Skip the header row
        split($16, date, "/")
        if (length(date[3]) == 2) {
            if (date[3] >= 20) {
                date[3] = "19" date[3]
            } else {
                date[3] = "20" date[3]
            }
        }
        $16 = sprintf("%04d/%02d/%02d", date[3], date[1], date[2])
    }
    print
}' tmdb-movies-transformed.csv > tmdb-movies-date-formatted.csv


sort -t',' -k16 -r tmdb-movies-date-formatted.csv > tmdb-movies-release-date-sorted.csv

#2. Lọc ra các bộ phim có đánh giá trung bình trên 7.5 rồi lưu ra một file mới
awk -F',' '$18 > 7.5 {print}' tmdb-movies-release-date-sorted.csv > over_7-5_rated_movies.csv

#3. Tìm ra phim nào có doanh thu cao nhất và doanh thu thấp nhất
awk -F',' 'NR>1 {
    if ($5 != "" && ($5 > max || max == "")) {max = $5; max_title = $6}
    if ($5 != "" && ($5< min || min == "")) {min = $5; min_title = $6}
}

END {
    print "Highest revenue: " max_title " - " max
    print "Lowest revenue: " min_title " - " min
}' tmdb-movies-release-date-sorted.csv

#4. Tính tổng doanh thu tất cả các bộ phim
awk -F',' 'NR>1 {sum += $5} END {print "Total revenue: $" sum}' tmdb-movies-release-date-sorted.csv

#5. Top 10 bộ phim đem về lợi nhuận cao nhất
awk -F',' 'NR>1 {profit=$5-$4; print "$" profit ", " $6}' tmdb-movies-release-date-sorted.csv | sort -t',' -k1 -nr | head -n 10

#6. Đạo diễn nào có nhiều bộ phim nhất và diễn viên nào đóng nhiều phim nhất
awk -F',' 'NR>1 {
    split($9, directors, "|")
    for (d in directors) director_count[directors[d]]++
    split($7, actors, "|")
    for (a in actors) actor_count[actors[a]]++
}
END {
    max_director = max_actor = ""
    max_director_count = max_actor_count = 0
    for (d in director_count)
        if (director_count[d] > max_director_count) {
            max_director = d
            max_director_count = director_count[d]
        }
        
    for (a in actor_count)
        if (actor_count[a] > max_actor_count) {
            max_actor = a
            max_actor_count = actor_count[a]
        }
    print "Director with most films: " max_director " (" max_director_count " films)"
    print "Actor in most films: " max_actor " (" max_actor_count " films)"
}' tmdb-movies-release-date-sorted.csv > dir_cast_most_films.txt


#7. Thống kê số lượng phim theo các thể loại. Ví dụ có bao nhiêu phim thuộc thể loại Action, bao nhiêu thuộc thể loại Family, ….
awk -F',' 'NR>1 {
    split($14, genres, "|")
    for (g in genres) genre_count[genres[g]]++
}
END {
    for (g in genre_count)
        print g ": " genre_count[g] " films"
}' tmdb-movies-release-date-sorted.csv | sort -t':' -k2 -nr > num_movies_by_genres.txt