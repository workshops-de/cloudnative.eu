---
title: How to containerize a Python application
description: Learn how to run a Python application inside a container
author: "Christian Barra"
published_at: 2020-10-20 11:00:00
header_source: https://unsplash.com/photos/FtRkRespN24?utm_source=unsplash&utm_medium=referral&utm_content=creditShareLink
header_image: header.jpg
categories: "docker"
language: "en"
---

##### Containers are everywhere, but how do you run a Python application inside a Docker container? This article will show you how!

*In case you are wondering, the examples require Python 3.x*.

Before diving into containers, let’s talk a bit more about the Python application we want to containerize.

The application is a web API that returns a random movie from a movie collection. Inside our local folder we have 3 files:


```bash
app.py # Python application
movies.json # movie collection
requirements.txt # where we specifiy our Python dependencies
```

`app.py` contains one API endpoint that returns a random movie:

```python
import os
import json
from pathlib import Path
from random import choice
import cherrypy

PORT = os.environ.get('PORT', 8888)

FOLDER_PATH = Path(__file__).parent

with open(FOLDER_PATH / "movies.json", "r") as f:
    MOVIES = json.loads(f.read())

class Movie:
    @cherrypy.expose
    @cherrypy.tools.json_out()
    def index(self):
        return {"movie": choice(MOVIES)}

cherrypy.quickstart(
    Movie(), config=cherrypy.config.update({
        'server.socket_host': '0.0.0.0',
        'server.socket_port': PORT,
        }))
```

Inside `requirements.txt`, we have our dependencies and after running

```bash
pip install -r requirements.txt
```
we are able to run our application with `python app.py`.

Running `curl localhost:8888` should return a random movie, something like:

```json
{
  "movie": {
    "Title": "Opal Dreams",
    "US_Gross": 14443,
    "Worldwide_Gross": 14443,
    "US_DVD_Sales": null,
    "Production_Budget": 9000000,
    "Release_Date": "Nov 22 2006",
    "MPAA_Rating": "PG",
    "Running_Time_min": null,
    "Distributor": "Strand",
    "Source": "Based on Book/Short Story",
    "Major_Genre": "Drama",
    "Creative_Type": "Contemporary Fiction",
    "Director": null,
    "Rotten_Tomatoes_Rating": null,
    "IMDB_Rating": 6.5,
    "IMDB_Votes": 468
  }
}
```

Cool, the application is working!

### How do we containerize our application?

**Containerizing a Python application means creating a Docker image that has everything needed to run it: source code, dependencies and configuration.**.

The first step to containerize our application is to create a new text file, named `Dockerfile`:

```bash
app.py
movies.json
requirements.txt
Dockerfile
```

Inside the `Dockerfile` (for what we consider a minimal viable `Dockerfile`), we need to specify three steps:

- Select the base image we want to use
- Select the files we want to copy inside the Docker image
- Install the app's dependencies

### Base image

To specify a base image, we use the [FROM command](https://docs.Docker.com/engine/reference/builder/#from) followed by either a private or public image.

In our case, we will use the [official Python Docker image](https://hub.Docker.com/_/python), available on the Docker hub.

We will select the latest available Python 3 image based on Ubuntu.

```Dockerfile
# 1. Base image
FROM python:3.8.5-slim-buster
```

The image name is made up of two different parts: `image:tag`. In our case the image is `python` and the tag is `3.8.5-slim-buster`.

That's everything we need for the first step.

### Copy our application
To copy our application inside the Docker image, we will use the [COPY command](https://docs.Docker.com/engine/reference/builder/#copy):

```Dockerfile
# 2. Copy files
COPY . /src
```

This command copies the specified files (or folder) into the Docker image. In our case, we want to copy all files available in our local folder inside the Docker image under the `/src` path.

It's important to note that the first part of the `COPY` command is a path relative to the context of the build and not to our local machine.

### Install the requirements.txt

The last step is to install our dependencies inside the Docker image. To achieve that we will use the [RUN command](https://docs.Docker.com/engine/reference/builder/#run) to `RUN` pip install:

```Dockerfile
# 3. Install our deps
RUN pip install -r /src/requirements.txt
```

One thing to notice is that the path of `requirements.txt` is different compared with the first time we ran `pip install`.

The reason behind this is that the copied files are under the `/src` path inside the image.


### Build and run a Docker image

```Dockerfile
# 1. Base image
FROM python:3.8.3-slim-buster

# 2. Copy files
COPY . /src

# 3. Install our deps
RUN pip install -r /src/requirements.txt
```

Our `Dockerfile` is now complete and we can use it to build a Docker image. For that we need to use the `docker build` command:

```bash
docker build -t movie-recommender .
```

This command builds a Docker image named `movie-recommender` using your current folder as building context (the `.` at the end specifies the path of the building context we want to use).

Now we can run the image we just built using the `docker run` command:

```bash
docker run movie-recommender python /src/app.py
```

This command will execute `python /src/app.py` inside a container based on the `movie-recommender` image.

However, if we try to connect to our application using `curl localhost:8888`, we will get an error.

How is that possible? Why can't we connect to our application that runs inside the container?

**The reason is that we didn’t expose our application's port to the local machine**. We can do that by using the [`-p HostPort:ContainerPort` flag](https://docs.docker.com/engine/reference/run/#expose-incoming-ports).

So let’s try to rerun the command again, this time specifying that we want to expose port `8888` locally:

```bash
docker run -p 8888:8888 movie-recommender python /src/app.py
```

and then `curl localhost:8888`.

Now it works—great! We just containerized a Python application!


## Quick recap

- Containerizing an application means to create a Docker image that has everything needed to run it—source code, libraries, and configuration.
- We used a Dockerfile to specify how to build a Docker image.
- `docker build` builds a Docker image starting from a `Dockerfile`.
- `docker run` runs a container using a Docker image.


## Useful resources

- [Github repo for movie-recommender](https://github.com/py-bootcamp/movie-recommender/tree/part-1)
- [Dockerfile reference](https://docs.Docker.com/engine/reference/builder/)
- [Docker run](https://docs.Docker.com/engine/reference/run/)
- [Docker build](https://docs.Docker.com/engine/reference/commandline/build/)
