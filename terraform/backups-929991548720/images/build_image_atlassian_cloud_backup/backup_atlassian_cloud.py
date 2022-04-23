#!/usr/bin/env python

import requests
import time
import re
import argparse
import os


BASE_URL = "https://{}.atlassian.net"


class AtlassianBackup:
    def __init__(self, account_id, base_url, user_name, token, component):
        self.account_id = account_id
        self.base_url = base_url
        self.user_name = user_name
        self.token = token
        self.session = self._get_session()

        if component in ["confluence", "jira"]:
            self.component = component
        else:
            raise NotImplementedError


    def _get_session(self):
        session = requests.Session()
        session.auth = (self.user_name, self.token)
        session.headers.update(
            {"Accept": "application/json", "Content-Type": "application/json"}
        )
        return session

    def create_backup_confluence(self):
        url = requests.compat.urljoin(self.base_url, "/wiki/rest/obm/1.0/runbackup")
        backup_request = self.session.post(
            url, data=b'{"cbAttachments": "true", "exportToCloud": "true"}'
        )

        if not backup_request.ok:
            print(f"Error: {backup_request.text}")
            print(backup_request.status_code)
            exit(1)

    def create_backup_jira(self):
        url = requests.compat.urljoin(
            self.base_url, "/rest/backup/1/export/runbackup")
        backup_request = self.session.post(
            url, data=b'{"cbAttachments": "true", "exportToCloud": "true"}'
        )

        if not backup_request.ok:
            print(f"Error: {backup_request.text}")
            exit(1)

        url = requests.compat.urljoin(
            self.base_url, "/rest/backup/1/export/lastTaskId")
        task_request = self.session.get(url)
        task_id = task_request.text

        return task_id

    def wait_for_backup_confluence(self):
        backup_progress_url = requests.compat.urljoin(
            self.base_url, "/wiki/rest/obm/1.0/getprogress"
        )

        for _ in range(2880):
            backup_progress_res = self.session.get(backup_progress_url).json()
            print(f"Debug: {backup_progress_res}")

            if backup_progress_res["alternativePercentage"] == "100%" and "fileName" in backup_progress_res:
                return backup_progress_res["fileName"]

            else:
                print(
                    f"Backup is {backup_progress_res['alternativePercentage']} ready, waiting for 100% completion."
                )
                time.sleep(10)

        print("Backup timed out")
        exit(1)

    def wait_for_backup_jira(self, task_id):
        backup_progress_url = requests.compat.urljoin(
            self.base_url, f"/rest/backup/1/export/getProgress?taskId={task_id}"
        )

        for _ in range(1440):
            backup_progress_res = self.session.get(backup_progress_url).json()
            if backup_progress_res["status"] == "Success":
                return backup_progress_res["result"]
            else:
                print(
                    f"Backup is not ready yet, status is {backup_progress_res['status']}, progress: {backup_progress_res['progress']}"
                )
                time.sleep(10)

        print("Backup timed out")
        exit(1)

    def download_backup(self, backup_url: str, destination_dir: str):
        ts = time.strftime("%Y%m%d_%H%M")

        if self.component == "jira":
            backup_name = f"backup_{self.component}_{self.account_id}_{ts}.zip"
            url_prefix = "/plugins/servlet/"
        elif self.component == "confluence":
            backup_name = f"backup_{self.component}_{self.account_id}_{ts}.zip"
            url_prefix = "/wiki/download/"

        with self.session.get(
            requests.compat.urljoin(
                self.base_url, url_prefix) + backup_url,
            stream=True,
        ) as r:
            r.raise_for_status()
            with open(os.path.join(destination_dir, backup_name), "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)

        print(
            f"Saved to {os.path.join(destination_dir, backup_name)} successfully.")


def main():
    parser = argparse.ArgumentParser("Cloud Jira & Confluence backup")
    parser.add_argument(
        "-a",
        "--account-id",
        help="Atlassian Cloud account id, https://<account-id>.atlassian.net",
        default=os.getenv("ATLASSIAN_ACCOUNT_ID"),
    )
    parser.add_argument(
        "-u",
        "--user",
        help="Email address for Atlassian Cloud account",
        default=os.getenv("ATLASSIAN_USER_ID"),
    )
    parser.add_argument(
        "-t",
        "--token",
        help="API token for the user account",
        default=os.getenv("ATLASSIAN_TOKEN"),
    )
    parser.add_argument(
        "-d",
        "--destination",
        help="Destination directory for the backup file",
        default=".",
    )

    args = parser.parse_args()


    confluence_backup = AtlassianBackup(
        account_id=args.account_id,
        base_url=BASE_URL.format(args.account_id),
        user_name=args.user,
        token=args.token,
        component="confluence"
    )

    backup_task_id = confluence_backup.create_backup_confluence()
    backup_url = confluence_backup.wait_for_backup_confluence()
    confluence_backup.download_backup(backup_url=backup_url, destination_dir=args.destination)


    jira_backup = AtlassianBackup(
        account_id=args.account_id,
        base_url=BASE_URL.format(args.account_id),
        user_name=args.user,
        token=args.token,
        component="jira"
    )

    backup_task_id = jira_backup.create_backup_jira()
    backup_url = jira_backup.wait_for_backup_jira(task_id=backup_task_id)
    jira_backup.download_backup(backup_url=backup_url, destination_dir=args.destination)


if __name__ == "__main__":
    main()
