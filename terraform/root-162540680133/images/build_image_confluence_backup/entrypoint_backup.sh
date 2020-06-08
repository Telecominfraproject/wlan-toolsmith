set -e

export BACKUP_DIR=backup_dir

mkdir $BACKUP_DIR


echo "Backing up confluence for $ATLASSIAN_ACCOUNT_ID .."
python3 /backup_confluence.py --account-id $ATLASSIAN_ACCOUNT_ID --user $ATLASSIAN_USER --token $ATLASSIAN_TOKEN --destination $BACKUP_DIR
echo "Generated backup successfully $(ls $BACKUP_DIR/*.zip)"

echo "Uplaoding to s3 bucket $BACKUP_BUCKET"
aws s3 cp $BACKUP_DIR/*.zip s3://${BACKUP_BUCKET}/confluence/

echo "Done."
