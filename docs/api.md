# API Reference

# Authorisation

The server expects an API key to be included in a header for all API requests:

```
Authorization: Bearer your_api_key
```

<aside class="notice">
You must replace <code>your_api_key</code> with your issued API key.
</aside>


**To authorise, use this code:**

```shell
# With shell, you can just pass the correct header with each request
curl "api_endpoint_here"
  -H "Authorization: Bearer your_api_key"
```

# Retrieving Records

The "provider" and "course" endpoints support retrieving records changed
since the last request. This is intended to reduce the data transfer volumes
and processing needed to synchronise the UCAS apply system with DfE's course
data on a schedule.

The expected usage is as follows:

## Populating an empty system


1. Call the endpoint with no query parameters,
   e.g. `GET https://.../api/v1/<recruitment_cycle>/providers`
2. The API will return the first page of records, and will include a response
   header indicating the url needed to request the next page of records.
3. Make another GET using the provided next page url.
4. Repeat until no data is returned. Keep a copy of the next-page url
   provided along with the empty response in order to be able to fetch
   records that change after this initial load.

*The above can also be used to refetch all the data periodically to eliminate any drift
that has crept in over time*

## Retrieving changed records

1. Make a GET request using the next-page url provided with the empty
   response at the end of the last full or incremental fetch.
2. The API will return the first page of records, and will include a response
   header indicating the url needed to request the next page of records.
3. Make another GET using the provided next page url.
4. Repeat until no data is returned. Keep a copy of the next-page url
   provided along with the empty response in order to be able to fetch
   records that change after this initial load.

Records will be repeated as new changes are recorded so the client **must**
be able to handle duplicate entries in the result sets.

The header will be of the form with the contents of `<...>` replaced with the
correct url:

```
Link: <https://.../api/v1/recruitment_cycle/providers?...>; rel="next"
```

**The query parameters are considered an interal concern of the API** and
**must not** be constructed manually in order to avoid losing changes. The
incremental update should only be performed using the next-page urls provided
in the response headers. With that in mind, these are the parameters you
should expect to see:

* `changed_since` - is an ISO 8601 timestamp stating the oldest change to include
* `from_entity_id` where "entity" is "provider" or "course" - is an internal id
  used in paging to ensure no ambiguity where record updates within the same
  second have been split across pages

This is based on the [link header
pagination](https://apievangelist.com/2016/05/02/http-header-awareness-using-the-link-header-for-pagination/)

# Errors

The API uses the following error codes:

Error Code | Meaning
---------- | -------
400        | Bad Request -- Your request is invalid.
401        | Unauthorized -- Your API key is wrong.
404        | Not Found -- The specified resource could not be found.
500        | Internal Server Error -- We had a problem with our server. Try again later.
503        | Service Unavailable -- We're temporarily offline for maintenance. Please try again later.

# Preparation for the next recruitment cycle (rollover)

During a given recruitment cycle, there will be a period when providers have two sets of courses to manage – one set of courses that are currently published for the current recruitment cycle, and unpublished courses being preparated for the next recruitment cycle. Additionally, the providers who deliver next year's courses may change, and they may have different campuses for the same courses. The point in time when the overlap starts is referred to as rollover, and typically happens in or around May.

To differentiate between entities from different recruitment cycles, each endpoint has a `<recruitment_cycle>` part in the URL. Additionally, the following entities have a `recruitment_cycle` attribute:

- course
- campus
- campus status

# Endpoints

## Courses

### Entity documentation

Parameter            | Data type                   | Possible values              | Description
---------            | ---------                   | ---------------              | -----------
course_code          | Text                        | 4-character strings          | 4-character course code
start_month          | ISO 8601 date/time string   |                              | The month and year when the course starts
start_month_string   | Text                        | January, February, etc       | The month when the course starts as a string
name                 | Text                        |                              | Course title
copy_form_required   | Text                        | 'Y' or 'N'                   |
profpost_flag        | Text                        | "", "PF", "PG", "BO"         | Maximum of 2-characters
program_type         | Text                        | "SC", "SS", "TA", "SD", "HE" | Maximum of 2-characters
modular              | Text                        | "", "M"                      | Maximum of 1-character
english              | Integer                     | 1, 2, 3, 9                   |
maths                | Integer                     | 1, 2, 3, 9                   |
science              | Integer                     | 1, 2, 3, 9, null             |
recruitment_cycle    | Text                        |                              | 4-character year
campus_statuses      | An array of campus statuses |                              | See the campus status entity documentation below
subjects             | An array of subjects        |                              | See the subject entity documentation below
provider             | Provider                    | A provider entity            | See the provider entity documentation below
accrediting_provider | Provider                    | null or a provider entity    | See the provider entity documentation below
age_range            | Text                        | "P", "S", "M", "O"           | Age of students targeted by this course.

#### Course codes

Course codes:

- are unique within a provider
- are not unique across providers
- are stable across rollover (i.e. by default, a course in a particular subject delivered by the same provider will have the same course code across different recruitment cycles)

### Get all courses

This endpoint retrieves all courses.

#### HTTP Request

```
GET https://manage-courses-backend.herokuapp.com/api/v1/<recruitment_cycle>/courses
```

#### URL Parameters

Parameter         | Description
---------         | -----------
recruitment_cycle | 4-character year (e.g. 2019 for 2019/20 courses)

#### Example

```shell
curl "https://manage-courses-backend.herokuapp.com/api/v1/2019/courses"
  -H "Authorization: Bearer your_api_key"
```

**The above command returns JSON structured like this:**

```json
[
  {
    "course_code": "36B3",
    "start_month": "2019-09-01T00:00:00.000Z",
    "start_month_string": "September",
    "name": "Mathematics",
    "study_mode": "F",
    "copy_form_required": "Y",
    "profpost_flag": "PG",
    "program_type": "SD",
    "modular": "M",
    "english": 1,
    "maths": 3,
    "science": null,
    "qualification": 1,
    "recruitment_cycle": "2019",
    "age_range": "S",
    "campus_statuses": [
      {
        "campus_code": "-",
        "name": "Main Site",
        "vac_status": "F",
        "publish": "Y",
        "status": "R",
        "course_open_date": "2018-10-09",
        "recruitment_cycle": "2019"
      }
    ],
    "subjects": [
      {
        "subject_name": "Secondary",
        "subject_code": "05"
      },
      {
        "subject_name": "Mathematics",
        "subject_code": "G1"
      }
    ],
    "provider": {
      "institution_code": "2G9",
      "institution_name": "Outwood Institute of Education North",
      "institution_type": "Y",
      "accrediting_provider": "Y",
      "address1": "Sydney Russell School",
      "address2": "Parsloes Avenue",
      "address3": "Dagenham",
      "address4": "Essex",
      "postcode": "RM9 5QT"
    },
    "accrediting_provider": {
      "institution_code": "D86",
      "institution_name": "Durham University",
      "institution_type": "Y",
      "accrediting_provider": "Y"
    }
  },
  {
    ...
  }
]
```

### Get changed courses

This endpoint supports retrieving courses that have changed since the
specified point in time, see the [Retrieving Changed
Records](#retrieving-changed-records) section.

The returned results:

- match the structure of the [Get all courses](#get-all-courses) endpoint
- are sorted chronologically with the oldest update first
- are paginated with a page size of 100 (see the [pagination section](#pagination) for info about navigating pages)

A course is marked as changed (and hence included in this endpoint) if:

- the course itself has been changed
- the campus status has changed
- campus associations have changed
- subject associations have changed

#### HTTP Request

```
GET https://manage-courses-backend.herokuapp.com/api/v1/<recruitment_cycle>/courses?changed_since=<iso-8601-timestamp>
```

#### URL Parameters

| Parameter           | Description                                                           |
| ------------------- | --------------------------------------------------------------------- |
| recruitment_cycle   | 4-character year (e.g. 2019 for 2019/20 courses)                      |
| changed_since       | [ISO 8601 date/time string](https://en.wikipedia.org/wiki/ISO_8601)   |

## Campuses

### Entity documentation

Parameter         | Data type | Possible values     | Description
---------         | --------- | ---------------     | -----------
campus_code       | Text      | A-Z, 0-9, "-" or "" | 1-character campus codes
name              | Text      |                     |
region_code       | Text      | 01 to 11            | 2-character string
recruitment_cycle | Text      |                     | 4-character year

<aside class="warning">
A single provider can have at most 37 campuses.
</aside>

## Campus statuses

### Entity documentation

Parameter         | Data type            | Possible values   | Description
---------         | ---------            | ---------------   | -----------
campus_code       | Text                 | A-Z, 0-9, "-", "" | 1-character campus codes
name              | Text                 |                   |
vac_status        | Text                 |                   |
publish           | Text                 |                   |
status            | Text                 |                   |
course_open_date  | ISO 8601 date string |                   |
recruitment_cycle | Text                 |                   | 4-character year

## Subjects

### Entity documentation

Parameter    | Data type | Possible values     | Description
---------    | --------- | ---------------     | -----------
subject_code | Text      | 2-character strings | 2-character subject codes
subject_name | Text      |                     |

### Get all subjects

This endpoint retrieves all subjects.

#### HTTP Request

```
GET https://manage-courses-backend.herokuapp.com/api/v1/<recruitment_cycle>/subjects
```

#### URL Parameters

Parameter         | Description
---------         | -----------
recruitment_cycle | 4-character year (e.g. 2019 for 2019/20 courses)

#### Example

```shell
curl "https://manage-courses-backend.herokuapp.com/api/v1/2019/subjects"
  -H "Authorization: Bearer your_api_key"
```

**The above command returns JSON structured like this:**

```json
[
  {
    "subject_name": "Chinese",
    "subject_code": "T1"
  },
  {
    ...
  }
]
```

## Providers

### Entity documentation

Parameter              | Data type          | Possible values                                                                                                                                                                                                                                                                                                      | Description
---------              | ---------          | ---------------                                                                                                                                                                                                                                                                                                      | -----------
institution_code       | Text               | 3-character strings                                                                                                                                                                                                                                                                                                  | 3-character UCAS institution code
institution_name       | Text               |                                                                                                                                                                                                                                                                                                                      | The institution's full-length marketing name
institution_type       | Text               | "Y", "B", "0", "O", null                                                                                                                                                                                                                                                                                             | The type of institution (whether it's a university, lead school/teaching school alliance or a SCITT)
accrediting_provider   | Text               | "Y" or "N"                                                                                                                                                                                                                                                                                                           | Whether the provider can accredit courses or not
campuses               | An array of campus |                                                                                                                                                                                                                                                                                                                      | See the campus entity documentation above
address1               | Text               |                                                                                                                                                                                                                                                                                                                      | Address line 1
address2               | Text               |                                                                                                                                                                                                                                                                                                                      | Address line 2
address3               | Text               |                                                                                                                                                                                                                                                                                                                      | Town/City
address4               | Text               |                                                                                                                                                                                                                                                                                                                      | County
postcode               | Text               |                                                                                                                                                                                                                                                                                                                      | Postcode
region_code            | Text               | 01 to 11                                                                                                                                                                                                                                                                                                             | 2-character string
data_download_format   | Text               | `ASCII DATA`, `ASCII DATA and UNICODE DATA` or `Unicode data`                                                                                                                                                                                                                                                        |
oustanding_decisions   | Text               | `Alphabetic`, `Application code`, `Course / Alphabetic`, `Course / Application code`, `Course / Learner Number`, `Faculty / Alphabetic`, `Faculty / Application code`, `Faculty / Course / Alphabetic`, `Faculty / Course / Application code`, `Faculty / Course / Learner code`, `Not required` or `Learner Number` |
require_copy_forms     | Text               | `No, not required` or `Yes, required`                                                                                                                                                                                                                                                                                |
star_j                 | Text               | `UCAS link` or `Flat file`                                                                                                                                                                                                                                                                                           |
star_x                 | Text               | `No, not required` or `Yes, required`                                                                                                                                                                                                                                                                                |
utt_application_alerts | Text               | `No, not required`, `Yes, required`, `Yes - only my programmes` or `Yes - for accredited programmes only`                                                                                                                                                                                                            | New UTT Application alerts
type_of_gt12           | Text               | `Coming / Enrol`, `Coming or Not`, `No response` or `Not coming`                                                                                                                                                                                                                                                     |
scheme_member          | Text               | `Y` or `N`                                                                                                                                                                                                                                                                                                           |

### Get all providers

This endpoint retrieves all institutions.

#### HTTP Request

```
GET https://manage-courses-backend.herokuapp.com/api/v1/<recruitment_cycle>/providers
```

#### URL Parameters

Parameter         | Description
---------         | -----------
recruitment_cycle | 4-character year (e.g. 2019 for 2019/20 courses)

#### Example

```shell
curl "https://manage-courses-backend.herokuapp.com/api/v1/2019/providers"
  -H "Authorization: Bearer your_api_key"
```

**The above command returns JSON structured like this:**

```json
[
  {
    "institution_code": "P60",
    "institution_name": "University of Plymouth",
    "institution_type": "Y",
    "accrediting_provider": "Y",
    "address1": "Sydney Russell School",
    "address2": "Parsloes Avenue",
    "address3": "Dagenham",
    "address4": "Essex",
    "postcode": "RM9 5QT",
    "region_code": "01",
    "scheme_member": "Y",
    "campuses": [
      {
        "campus_code": "",
        "name": "Main Site",
        "recruitment_cycle": "2019",
        "region_code": "01"
      }
    ]
  },
  {
    ...
  }
]
```

### Get changed providers

This endpoint supports retrieving providers that have changed since the
specified point in time, see the [Retrieving Changed
Records](#retrieving-changed-records) section.

The returned results:

- matches the structure of the [Get all providers](#get-all-providers) endpoint
- are sorted chronologically with the oldest update first
- are paginated with a page size of 100 (see the [pagination section](#pagination) for info about navigating pages)

A provider is marked as changed (and hence included in this endpoint) if:

- the provider itself has been changed (including contact data changes)
- any of the associated campuses has changed
- campus associations have changed

#### HTTP Request

```
GET https://manage-courses-backend.herokuapp.com/api/v1/<recruitment_cycle>/providers?changed_since=<iso-8601-timestamp>
```

#### URL Parameters

Parameter         | Description
---------         | -----------
recruitment_cycle | 4-character year (e.g. 2019 for 2019/20 courses)
changed_since     | [ISO 8601 date/time string](https://en.wikipedia.org/wiki/ISO_8601)
