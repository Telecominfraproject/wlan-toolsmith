set -e

python3 /repo_list.py

mkdir repositories

for repo in $(cat repo_list.txt); do
    echo "Backing up ${repo} .."
    echo "Cloning https://****:x-oauth-basic@github.com/${GITHUB_ORGANIZATION}/${repo}.git repo"
    
    git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${GITHUB_ORGANIZATION}/${repo}.git
    cd ${repo}/
    for branch in $(git branch --all | grep '^\s*remotes' | egrep --invert-match '(:?HEAD|master)$'); do
        git branch --track "${branch##*/}" "$branch"
    done
    git fetch --all
    
    echo "Resetting origin rul to https://github.com/${GITHUB_ORGANIZATION}/${repo}.git"
    git remote set-url origin https://github.com/${GITHUB_ORGANIZATION}/${repo}.git
    cd /root
    
    tar czf ${repo}.tgz ${repo}
    aws s3 cp ${repo}.tgz s3://${BACKUP_BUCKET}/repositories/${repo}.tgz
    rm -fr ${repo}.tgz
    echo "Done."
done