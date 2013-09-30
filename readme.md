# PushFlashBang 2

- PushFlashBang was a good idea that tried to do too much and fell over at some linguistic challenges
- V2 is bringing back the core ideas in a simpler model
- The goal, to quickly learn vocabulary with passable pronunciation whilst traveling
- This version doesn't do content addition. This is all handled by deployed yaml files
- There is no user model. If you want a copy, install your own
- There is no timing data. I originally captured timing data in order to better track the user's learning
- There is no history. That's a nice to have and you're welcome to add it.
- The focus is on reading, translating and some speaking. Listening, writing and typing are out of this version
- There is no cross language madness. I am no longer supporting Spanish via Russian. It all comes back to some other language, usually English.
- Sentences are in; they were not in the original but I think they will be important.
- Pronunciation guidance is in. It was one of the best parts
- The spaced repetition is back WITH the dynamic algorithm that tailors to how good you are.


# Requires
- Sinatra hosts the thing
- YAML files provide content
- MongoDB is used for persistence. It should run on localhost and the usual port. It should not be public.


# Immediate Plans

- Question marks don't make valid routes
- Make the test data not chinese