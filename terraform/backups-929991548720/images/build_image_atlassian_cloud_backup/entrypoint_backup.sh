set -e

export BACKUP_DIR=backup_dir

mkdir $BACKUP_DIR

echo "Backing up $ATLASSIAN_ACCOUNT_ID .."
python3 /backup_atlassian_cloud.py --account-id $ATLASSIAN_ACCOUNT_ID --user $ATLASSIAN_USER --token $ATLASSIAN_TOKEN --destination $BACKUP_DIR
echo "Generated backup successfully $(ls $BACKUP_DIR/*.zip)"

echo "Uploading to s3 bucket $BACKUP_BUCKET"
for f in $(ls $BACKUP_DIR/*.zip); do
    aws s3 cp $f s3://${BACKUP_BUCKET}/atlassian_cloud/
done

echo "Done."
