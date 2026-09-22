S
Speaker 1
0:08
Hey, what's going on, Killer?
S
Speaker 2
0:09
Hey, man. Hey, hey, hey.
S
Speaker 1
0:14
Have a day. How we doing?
S
Speaker 2
0:15
Oh, so far so good, man. So far, so good.
S
Speaker 3
0:18
Nice.
S
Speaker 2
0:18
Yeah. Yesterday we felt like a a sprint, like an actual sprint, like get stuff done, you know. Yeah,
S
Speaker 1
0:27
good good job moving and grooving.
S
Speaker 2
0:29
Glad that worked out. Yeah,
S
Speaker 1
0:30
really happy we were able to get everything up for Nasia to review before standup. That's
S
Speaker 4
0:39
the beauty
S
Speaker 1
0:40
of being in multiple time zones,
S
Speaker 2
0:41
yeah, it doesn't always work out, but that time it did. No, actually, the one thing I was gonna mention, I know that like we've been trying to go about this, like you know, get a spec, do a PR for the spec, then you know, kind of get it out there. But I was, you guys were like, we need it done, like it's a bug, like let's go. So I was like, let's just just do it. So I'll try and you know adhere to the what we're expecting most of the time, but yeah, I know yesterday was a little different case. So
S
Speaker 1
1:09
yeah, and thanks for hearing that. I know most folks aren't. We can maybe loosen that for now. You know, spec can move with the ticket. That I think we've been the code quality has been pretty high, which is great. Like not a lot of pushback on reviews and whatnot,
S
Speaker 2
1:29
for sure.
S
Speaker 1
1:29
Our dev reviews, so we can probably combine them, or or if you feel more comfortable creating the spec first, getting that reviewed first, yeah, whatever whatever makes sense for you, but all that structure goes out the window for this sucker.
S
Speaker 2
1:45
Okay, cool. Yeah, what do we got? Like, I'm here in vibe coding, so I know it's going to be kind of just throwing stuff at the wall, see what sticks, right?
S
Speaker 1
1:53
Yes, sir. So we've got so context here. So my in addition to all the other shit going on, my biggest initiative for the team is to make sure the backlog is healthier than it's been in in months. And what I mean by that is making sure that there's plenty of work that's in the ready for work status. Cool. You know, came up in in stand up today, but when we plan a sprint, ideally we have like you know two to three tickets per developer at the top of the sprint,
S
Speaker 2
2:30
right? Rather than
S
Speaker 1
2:31
rather than like what we had last sprint or what we typically have, which is like, oh, it's it's a random Thursday and I'm finished on my work. I'm looking for my next thing. It's like I can make your guys's life easier by making sure that we have the work plan now, so that when you finish task one, it's not oh man I got to go ask for work. It's like oh I have tasks two and three right here ready to go in the sprint for me to pick up, and the way that ties to this is, you know, as we're moving to React, Chad, CN, etc. Shay, as we do that, Shay is prototyping what functionality we want to build or extend or change, and in order for Shay to prototype those things, he needs us to create kind of the initial pages for him to prototype against, right?
S
Speaker 2
3:28
Right.
S
Speaker 1
3:30
So this is all to say that in order to make the backlog healthier, Shay needs to be able to prototype his stuff,
S
Speaker 2
3:38
right?
S
Speaker 1
3:38
So that we can then get tasks created based on those prototypes, and then you see how it all kind of ties together. Absolutely,
S
Speaker 2
3:48
yeah, yeah.
S
Speaker 1
3:50
So this this epic is to unblock Shay to enable him to do that stuff, and the way it's going to work is we're going to we're going to do these three pages in in this very quick vibe coded way, and we're going to start with the case detail page. So basically, the ask is you're going to take the Proteus front end as it is off off of main. You're gonna create a new branch called prototype main,
S
Speaker 2
4:25
okay,
S
Speaker 1
4:26
and build out the case detail page such that it has the same functionality as current atlas, and the the functionality is listed here, right? So it's not permissions. It's not. I mean, it is restricted access, but it's not permissions, and it's just this this body of functionality. Me and Shay have taken a look, and this is all kind of what we need. So the ask is to build this out in React and Chad CN, but not build it out well. So like, I don't want, and you can allow your LLM to make it as fine-tuned as you want, but in the iron triangle of you know quality, speed, and cost, cost is kind of out the window. So we kind of have the two between quality and speed. This is 100% 100% speed, 0% quality. So like, you know, allow the LLM to if it's going to create CSS files, that's great. If it's going to create components, that's great. But really, it's like time to market or whatever fucking terms you want to use.
S
Speaker 2
5:35
Yeah.
S
Speaker 1
5:36
So the goal is to get this functioning not pretty, but like functioning so that it works, so that we can get it over to Shay ASAP. Because frankly, if you know, the sooner we get this to him, the sooner he can start stuff. Does that and and the caveat here is is this is not going to tie into the Calista Backend, we need what we're calling JSON mock server, which there's already some stuff like that going on in Proteus. Basically, you know, if you know when we load up the the case page, it's hitting the case detail endpoint and it's getting the case name. You know, it's it has the case ID,
S
Speaker 2
6:19
yeah,
S
Speaker 1
6:20
and it's getting the case name, it's getting the case number, and then the jobs associated with it, and the case files associated with it. You're going to mock all that with JSON endpoints, and you're going to tell the LLM to be like, "Hey, take a look at the correlated endpoints in Atlas currently, and be like, you know, mock these endpoints with JSON data so that we have a single functioning case detail page, and it should have all the things like like you should be able to click on the file and like download it, but it's not actually going to download anything because it's going to be a fake file, right? And things like that. So it should have all the functionality and feel like it, but it's just going to be a facade, right? It's going to be it's going to be fake.
S
Speaker 2
7:02
Okay.
S
Speaker 1
7:03
And then the last thing is, once we do the case detail page, we'll go to the job detail page and the proceeding detail page, so that by the end of this epic, Shay has a case with jobs. He can click into the jobs and access the job detail page. He can click into the proceedings on that job and click on the proceedings there, right? And that's the request. And then Shay's going to take that and be able to modify things and clean it up as needed. The last thing I'm going to throw at you is so all of this work is going to live in the prototype main branch, where Shay is kind of going to live, and what's going to happen is in a month or so, when we build out the case detail page correctly in the Proteus front-end application,
S
Speaker 4
8:05
then
S
Speaker 1
8:06
we'll clear out this vibe-coded work that you're doing here and replace it with just like, oh, here's the case detail page. Like we'll we'll basically merge main into Proteus in the prototype main, so that Shay now has access to real cases, and we'll do the same with the job detail page, and we'll do the same with the proceeding detail page. So all this work is a temporary unlock for Shay that will eventually get overridden with like us building out the the proper pages. So it's just a real, it's just a real saying it for like the 100th time. Unlock for Shay. Yeah,
S
Speaker 2
8:46
yeah.
S
Speaker 1
8:46
And also gives you the opportunity to like see what React looks like, see what Proteus looks like, and Chad CN.
S
Speaker 2
8:53
Yeah.
S
Speaker 1
8:53
So it's a huge help, and that's the big picture. What's going on?
S
Speaker 2
9:00
Okay. Okay. A couple things. that I I have I actually have a handful of questions. Like as I go through like this handful of them. Typically, when I've done JSON background like that, use Express. You know, like that to to do that. You know, back like creating the endpoints, the APIs to do the calls, everything like that. I don't know enough about React. I'm still getting familiar with those, but I mean, is React and Shad Cn? Are they mostly like just I? I have to do more to learn. Like React is the framework, obviously, for you know replacing Vue and things like that, right? But Shad CN, I don't really know entirely what what's in that one.
S
Speaker 1
9:45
Yeah, that is a Shad CN is basically quasar.
S
Speaker 2
9:53
Oh, okay. So it's
S
Speaker 1
9:54
it's a it's a component library that we extend. Okay, that's easy. Okay,
S
Speaker 2
9:58
okay.
S
Speaker 1
10:00
Yeah, and again, like you, like I know this sounds shoddy, but like you won't if you tell the LLM to build it with that, like it will know what's going on. I actually don't have Proteus pulled locally, but
S
Speaker 2
10:15
all right, a
S
Speaker 1
10:16
lot of this is already figured out because if Lana's been working in Maine, which maybe she is not, okay, Lana's not been working in Maine, so maybe get Lana's branch, or she hasn't even pushed any of this up yet. So reach out to Lana and see if she can push up her code to a branch, and that's where you that's where you're going to start from. But like Larry's already started some of this, so like if we were to look at you know some components, yeah, like it's pulling in drawer title from component UI, like it's it's pulling in things already, and I think there's some. Let me see if I can pull this down. Let me take a look, because I think some of this JSON mocking and whatnot is already happening for
S
Speaker 2
11:08
us. Oh, then beautiful. Then I'll have to rethink that. Nice.
S
Speaker 1
11:12
Yeah.
S
Speaker 2
11:20
Okay.
S
Speaker 1
11:21
So if I'm in here, yeah, it's gonna yell because nothing's installed yet. Yeah, we've got. Show me so show me Shad CN. Yeah, so we are already using this in Proteus. So you'll find it. You should find some of this stuff already in there. You'll see more with what Lana's already built. But yeah, that's kind of where I'm like, the details of like properly using React and properly using Shadzi and stuff allow the LLM to just kind of do its thing and just talk with it to get the functionality that we need, because you can tell it. Say like, hey, I'm building, you know, I'm building this page for based on the Atlas page. You know, you can it will look at Atlas and look at Calisto and see how the case detail page works currently. And you'll basically just be guiding it. I know it's not proper and not fun, but that's kind of the ask here.
S
Speaker 2
12:44
No, it's it's still it's it's a it's interesting. I do have a another question. You mentioned actually actually okay. So how how we're deploying this one? Like we have like an ECS like I'm thinking it's a front end like how how is that no
S
Speaker 1
13:05
no deployment yet no deployment yet okay there's no CI/CD is figured out so it's just going to live on your local and then what what will happen is Shay will actually pull this branch to his computer and he should just be able to do like npm run dev or something like that, and then see the functioning page working.
S
Speaker 2
13:24
Okay, that that was a big thing. Great question.
S
Speaker 1
13:26
Great question.
S
Speaker 2
13:27
Yeah, I really wasn't certain how he was going to digest it. Like, is was it fully like he's just oh, I have an Azure profile, and I just go hit the endpoint. Like, no, we're actually giving him a legit like we're setting you up. Got it. Yeah.
S
Speaker 1
13:38
No, fantastic question.
S
Speaker 2
13:41
Um. Okay. okay, okay, okay. Oh, because it doesn't require any permissions, we don't have to touch Azure or anything like that. We don't have to worry about any of those things. So that clears that off the table. Now, okay, the design itself, I mean, is is down and dirty as we can make it. I mean, it could be three files, but obviously, when we start getting into how large these pages are with so many different components and how much it works, I mean, you get one monolith of this, and it's going to be a little bit chaotic. I mean, it can get you know quite large very quickly, and it becomes very costly. I know from just pulling in, you know, token wise, like you start doing everything in one giant file. Every call to that file is consuming that many tokens. Like that's the way it works, right? So I'm wondering, like, what's the, what's what's the like the division, like you know, how much broken down? Like, I mean, normally three files you can get a lot of it fit in there, but again, it's going to inflate it significantly.
S
Speaker 1
14:43
So I think my gut says if you you know tell it to kind of recreate what's in Atlas for the case detail page in that regard, it's probably going to copy a lot of that file structure for you. But even if it is three files, like you're saying, don't worry about the LLM costs, and don't necessarily worry about the hygiene of the file structures itself.
S
Speaker 2
15:09
Okay.
S
Speaker 1
15:10
As long as it works, it's real, real bare bones.
S
Speaker 2
15:13
Okay. The other thing then, and as far as like, even if it is like real bare bones and everything, for look and feel like once we get this one in there, you did say we're going to basically put in the new version once it's ready. We'll put you know this will be the the new home for it. Like we're just getting something in place at the moment just to kind of unlock that. So there is no maintenance behind this, right? Is that my understanding then?
S
Speaker 4
15:37
Correct.
S
Speaker 2
15:38
Okay, brilliant. That yeah, that was in fact, Shay
S
Speaker 1
15:42
Shay will be doing the maintenance because you'll output whatever Shadseana, you know, whatever is output, and Shay is going to mold it into his vision anyways. He just we're basically standing up like a Figma for him, if that makes sense, because that's how he's going to do the designing.
S
Speaker 2
15:58
Okay, brilliant, brilliant. Okay, yeah. Gosh, what other loose ends? Because this
S
Speaker 1
16:07
is. I see your amp directly behind you. Oh, do you see? You lean back and it added it to the frame. It's pretty funny.
S
Speaker 2
16:15
Yeah, I'm trying again. We can't can't force it now. Yeah, I got a. I have a pinky head back there and a calf. Nice. Did some rearranging a couple weeks ago, and had to bring those back into the room. Just felt felt right.
S
Speaker 1
16:28
Nice.
S
Speaker 2
16:30
Gosh, man, this actually sounds totally like I'm like. How many times I've done this? Like dozens of times. I'm like so ready for it. I just got to make sure I'm not running off in the wrong direction. As far as because this is the Proteus front end, poking around and hear what we already have. There are you have Husky, you know things like that. I mean that's typically how you get your your test harness stuff, right? Like having all those kind of things built in. Like, what's the expectation? Yeah, no worries.
S
Speaker 1
17:07
No, no testing. We're we're really
S
Speaker 2
17:10
yeah,
S
Speaker 1
17:11
really barefoots with this sucker. Really
S
Speaker 2
17:12
barefounds. Okay, and I guess any sort of cursor rules or any sort of build out that will that will come later. We don't have to worry about any of that stuff. I mean, I'm loving it. I'm loving it. I gotta one second. Let me just. It's it's sometimes when it feels too easy. It's that you know. It's like there's always like what's the gotcha? What's the hidden tax that I'm not aware of at this moment?
S
Speaker 1
17:47
I'm curious what happens if I run this sucker. Oh yeah, cool. So we already have.
S
Speaker 2
17:52
Oh, look at this.
S
Speaker 1
17:53
Open here. Open in my. So I just downloaded this npm installed, and this is what I get.
S
Speaker 2
17:59
Heck yeah.
S
Speaker 1
18:01
So like we already have like I think Larry vibe coded some shit, but we already have some stuff here. Obviously, this is not what the my cases page looks like.
S
Speaker 2
18:11
Yeah.
S
Speaker 1
18:12
So you'll you'll build yours out. Honestly, go ahead and build it out at and make a note of this prototype slash cases. Let's do that.
S
Speaker 2
18:23
Okay. Prototypes, and that's
S
Speaker 1
18:26
that's where your that's where your functionality will live.
S
Speaker 2
18:28
Prototype slash cases.
S
Speaker 1
18:30
Actually, because all this is junk. All this is not real. Just actually, just build it where it is. Build it. Build it at the cases level here. But yeah, you see, all this stuff is all this stuff is using the JSON backend. So if I look up this,
S
Speaker 2
18:48
yeah, is there a data folder or something, or what are we calling it?
S
Speaker 1
18:52
Yeah, it looks like we have the mocks fixtures fixtures.cs.cs
S
Speaker 2
18:58
file. Got it. All right.
S
Speaker 1
19:01
Yeah, so you should be able to leverage this stuff and just start fucking around with it.
S
Speaker 2
19:06
Hell yeah! No, this is great because this all makes perfect sense, and all the points are already getting in sick. Yeah, routes is
S
Speaker 1
19:13
where that's happening. So yeah, just terraform the the case. You know, you get into a case detail page.
S
Speaker 2
19:20
Yeah,
S
Speaker 1
19:21
like that's a proceed. Yeah, my case is yes. This is a case, and yeah, here you go. So like this, this will be kind of where you start and start just making it look more like our page.
S
Speaker 2
19:32
Yeah. Okay. So one thing I'm wondering is bare bones as it can be, and also for Shay's benefit, and I know that he's gonna he's gonna have to play a little bit of like understand he'll have to understand a little bit like if we're not making it exact, there's gonna be things that he's gonna need to clean up or he'll have to kind of overlook in this case, especially like responsive design, you know, like things like that, like like just really if if it has things that overlap because you like you know because some he he's I I just know from working with Shay that when it came to getting things specific, like oh half the screen has to be this far with you know, and then we're truncating it and we're getting the exact like you know there's things that he gets like super honed in on for like how it should look and feel, and I'm like you know I just making sure every like I'm not the only one who's like hey dude this is just don't worry about it. Like, right, it works. No,
S
Speaker 1
20:23
no, he he knows that he's expecting speed over quality, and also like there can be a little bit of churn. You know, you output whatever you output, and if he's like, oh, he can change this, this, and this, it's like, yeah, because this is super informal. Cool, but yeah. So my request would be, so I have this as a two-pointer. I would love to see, I would love to see this working by the end of today. I think working with LLMs. I think unless you have like a wall of meetings later, this should just be a couple hours.
S
Speaker 2
20:59
Yeah,
S
Speaker 1
21:00
and ideally, ideally, in a super ideal world, after figuring out this case detail page, I'd love to see the job detail and proceeding detail by the end of the day tomorrow, if possible.
S
Speaker 2
21:11
Okay.
S
Speaker 1
21:12
We'll see how this one goes, and that's just like the pass, right? So if you get the pass for case detail page at the end of the day today, you get it to Shay. Shay might have some feedback. We can apply it tomorrow. Yeah. But I'd love to see these three wrapped by the end of the day tomorrow. Worst case Monday is also fine. Like if it's one day per page. Oh yeah, it is. It
S
Speaker 2
21:31
is almost the end of the week. Okay.
S
Speaker 1
21:33
Yeah.
S
Speaker 2
21:34
Either way. No, that sounds great, man. Yeah. I mean, we're on Vibe code, so it's this is like yeah, it's not a like. Fortunately, it's low mental effort on my behalf, so I get to just say, "Hey, do it better.
S
Speaker 1
21:48
Damn right. I'm gonna bring all three of these to the. I'm gonna bring all three of these to the sprint.
S
Speaker 2
21:53
Sounds good.
S
Speaker 1
21:53
Yeah, and don't hesitate to ask questions as you're working through this, you know if you're like, oh, am I on the right track, or if you want me to take a look, I'm happy to do so. This is this is really going to be a big unlock for getting the sprints healthier.
S
Speaker 2
22:14
Sweet.
S
Speaker 1
22:15
So I appreciate it.
S
Speaker 4
22:16
Yeah.
S
Speaker 1
22:17
Let me make sure this is in the sprint now. Show it to me on the screen yet. Where is it?
S
Speaker 2
22:36
Oh, what's the? You said prototype for the branch, you know, like basically, you just use the pro. I can't remember the exact the way that you you framed it now in my head, but but for for when I deploy stuff, like, do you want me to use a ticket number or something like we did? We usually do, or is there? Yeah.
S
Speaker 1
22:58
Oh yeah.
S
Speaker 2
22:58
Okay. Sounds good.
S
Speaker 1
23:03
Cool. All
S
Speaker 4
23:04
right, dude.
S
Speaker 1
23:05
I'll I'll move this around. I'll move this around on the move this around offline. But here's your ticket for the first
S
Speaker 2
23:12
one. Heck yeah. All right, man. We'll get on then right now.
S
Speaker 1
23:17
Let's go. Thanks, dude.
S
Speaker 2
23:18
All right, no problem. Catch you, bite.
S
Speaker 1
23:20
See
S
Speaker 2
23:21
you.