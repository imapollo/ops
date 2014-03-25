from mongoengine import *
from blongo.settings import DBNAME

connect(DBNAME)

class Comment(EmbeddedDocument):
    content = StringField(max_length=500, required=True)
    # last_update = DateTimeField(required=True)

class Post(Document):
    title = StringField(max_length=120, required=True)
    content = StringField(max_length=500, required=True)
    last_update = DateTimeField(required=True)
    comments = ListField(EmbeddedDocumentField(Comment))

