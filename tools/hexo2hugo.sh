# imlk: This file is from https://gist.github.com/conoro/9fcd17f2673fb301ab6a631459d2926e
# Modifications:
# - add check for the range of front matter
# - replace <tab> in front matter with <space><space>
# - remove `[]` for items of tags and categories


# code is from http://helw.net/2015/07/19/migrating-to-hugo-from-hexo/
# Ran fine on Windows 10 with MSysGit installed
# cd to directory with all the md files from Hexo
# bash hexo2hugo.sh

# ensure dates don't start with single quotes, so we need 
# to replace `'` with ``
for file in *.md; do awk '{
    if (NF == 1 && $1 == "---") { count_divider++; }
    if (count_divider == 1 && $1 == "date:") {
        gsub("\047", "", $0); print;
    } else {
        print $0;
    }
}' "$file" >temp.md && mv temp.md "$file"; done

# fix the dates and add the three dashes as the first line
# convert
# date: 2018-01-19 21:41:51
# to
# date: 2018-01-19T21:41:51+08:00
# since I live in UTC+8
for file in *.md; do awk '{
    if (NF == 1 && $1 == "---") { count_divider++; }
    if (count_divider == 1 && $1 == "date:") {
        printf("%s %sT%s+08:00\n", $1, $2, $3);
    } else {
        print $0;
    }
}' "$file" >temp.md && mv temp.md "$file"; done

# # wrap dates with quotes that aren't wrapped in quotes
# for file in *.md; do awk '{
#     if (NF == 1 && $1 == "---") { count_divider++; }
#     if (count_divider == 1 && $1 == "date:") {
#         if ($2 ~ /^"/) {
#             print $0;
#         } else {
#             printf("%s \"%s\"\n", $1, $2);
#         }
#     } else { print $0; }
# }' "$file" >temp.md && mv temp.md "$file"; done


# fix
# Replace <tab> in front matter with <space><space>
for file in *.md; do awk '{
    if (NF == 1 && $1 == "---") { count_divider++; }
    if (count_divider == 1) {
        gsub("\t", "  ", $0); 
        print;
    } else {
        print $0;
    }
}' "$file" >temp.md && mv temp.md "$file"; done



# fix
# Remove `[]` for items of tags and categories
for file in *.md; do awk '{
    if (NF == 1 && $1 == "---") { count_divider++; }
    if (count_divider == 1) {
        if (need_replace == 1){
            gsub("\\[", "", $0); 
            gsub("\\]", "", $0); 
            print;
        }else{
            print $0;            
        }
        if ($1 ~ /:$/){ # should be a field
            if ($1 == "categories:" || $1 == "tags:") { need_replace=1; } else { need_replace=0; }
        }
    } else {
        print $0;
    }
}' "$file" >temp.md && mv temp.md "$file"; done


# used by myself:
# fix
# add aliases to support old links
for file in *.md; do awk '{
    if (NF == 1 && $1 == "---") { count_divider++; }
    if (count_divider == 1) {
        print $0;
        if (count_divider == 1 && $1 == "id:") {
            print "aliases:\n  - /blog/"$2"/";
        }
    } else {
        print $0;
    }
}' "$file" >temp.md && mv temp.md "$file"; done

