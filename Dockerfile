FROM python:3.7.4-alpine

RUN pip install youtube-dl awscli

#ENTRYPOINT [ "youtube-dl", "--write-info-json", "--write-all-thumbnails", "--skip-download" ]
#CMD [ "https://youtu.be/08vk9g-jcsM?t=6" ]
