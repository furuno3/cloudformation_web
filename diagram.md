``` mermaid
architecture-beta
    group users_vpc(logos:aws-vpc)[users_VPC]
        group public_subnet1[Public Subnet] in users_vpc
            service app_server1(logos:aws-ec2)[APP Instance] in public_subnet1

        group private_subnet1[Private Subnet] in users_vpc
            service db_server1(logos:aws-ec2)[DB Instance] in private_subnet1

    group corp_vpc(logos:aws-vpc)[corp_VPC]
        group public_subnet2[Public Subnet] in corp_vpc
            service app_server2(logos:aws-ec2)[APP Instance] in public_subnet2

        group private_subnet2[Private Subnet] in corp_vpc
            service db_server2(logos:aws-ec2)[DB Instance] in private_subnet2

app_server1:R -- L: db_server1
app_server2:R -- L: db_server2

```