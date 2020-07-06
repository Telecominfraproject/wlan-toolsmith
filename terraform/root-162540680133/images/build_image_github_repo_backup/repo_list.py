#!/usr/bin/env python

import requests
import os


GITHUB_URL = "https://api.github.com/orgs/{}/repos"


def main():
    github_token = os.getenv("GITHUB_TOKEN")
    github_org = os.getenv("GITHUB_ORGANIZATION")
    s3_bucket_name = os.getenv("BACKUP_BUCKET")
    repo_blacklist = os.getenv("REPO_BLACKLIST").split("|")
    
    res = requests.get(url=GITHUB_URL.format(github_org), auth=requests.auth.HTTPBasicAuth(github_token, "x-oauth-basic"))
    repo_list = [x["name"] for x in res.json()]
    print(f"Retrieved {len(repo_list)} for {github_org} organization: {', '.join(repo_list)}")

    repo_list_clean = [r for r in repo_list if r.lower() not in [b.lower() for b in repo_blacklist]]
    print(f"Removed blacklisted repos, {len(repo_list_clean)} left for {github_org} organization: {', '.join(repo_list_clean)}")

    with open("repo_list.txt", "w") as f:
        for repo in repo_list_clean:
            f.write(f"{repo}\n")

    print("Wrote repo list to repo_list.txt")


if __name__ == "__main__":
    main()