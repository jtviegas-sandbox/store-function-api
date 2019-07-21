# split4ever setup


## parts files structure
``
#number name    price   category    subcategory notes
1,"ferrugenta mas boa",12.34,"badanas","pequenas","e uma badana muito boa",20181201
2,"porta bagagem para levar a lua",123.46","portas bagagem","grandes","e um porta bagagem para campeoes",20181202
3,"ferro velho mas bom",23.98,"cenas","valiosas","e um ferrinho daqueles velho",20181203
``

## rationale
* create:
  * buckets:
    * parts.split4ever.com
    * functions.split4ever.com
  * tables
    * parts
    * parts_DEV
  * iam
    * groups:
      * s4e_parts_maintenance
    * roles:
      * s4e_parts_update
    * users:
      * tiago
      * rocha
    * policies
      * s4e_logs_policy
      * s4e_parts_bucket_maintenance_policy
      * s4e_parts_overall_maintenance_policy
      * s4e_update_function_buckets_policy
      * s4e_update_function_tables_policy
    * attach:
      * tiago - s4e_parts_maintenance
      * rocha - s4e_parts_maintenance
      * s4e_logs_policy - s4e_parts_maintenance
      * s4e_parts_bucket_maintenance_policy - s4e_parts_maintenance
      * s4e_parts_overall_maintenance_policy - s4e_parts_maintenance
      * s4e_parts_update - s4e_logs_policy
      * s4e_parts_update - s4e_update_function_buckets_policy
      * s4e_parts_update - s4e_update_function_tables_policy
  * functions:
  	* s4e_parts_update_event_function
    * permission:
      * "lambda:InvokeFunction" - "arn:aws:s3:::parts.split4ever.com"
  
...at this stage one must just add an event to   "arn:aws:s3:::parts.split4ever.com"
to invoce "s4e_parts_update_event_function" when some file is added/updated

