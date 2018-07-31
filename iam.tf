resource "aws_iam_instance_profile" "storage-baker" {
  name = "storage_baker"
  role = "${aws_iam_role.storage-baker.name}"
}
resource "aws_iam_role" "storage-baker" {
    name               = "storage_baker"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "ebs-baker" {
    name        = "ebs_baker"
    description = "EBS baker for dynamicaly attach/detach into host and container"
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:CopySnapshot",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteSnapshot",
                "ec2:DeleteTags",
                "ec2:DeleteVolume",
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeTags",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:ModifySnapshotAttribute",
                "ec2:ModifyVolume",
                "ec2:ModifyVolumeAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "s3fs-baker" {
    name        = "s3fs_baker"
    description = "S3FS baker for dynamicaly attach/detach into host and container"
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:CreateBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "ebs-baker-attach" {
    role       = "${aws_iam_role.storage-baker.name}"
    policy_arn = "${aws_iam_policy.ebs-baker.arn}"
}
resource "aws_iam_role_policy_attachment" "s3fs-baker-attach" {
    role       = "${aws_iam_role.storage-baker.name}"
    policy_arn = "${aws_iam_policy.s3fs-baker.arn}"
}
