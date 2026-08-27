
Oh yeah. So what what do we have here? What is the well the ticket I sent over? So I guess I'm actually kind of wondering like what Larry's comment this morning was to like kind of pick apart each one, figure out like what the problems are and like where the like what can be removed, what can't. So I just kind of went through each one. You know, I started with that. You know, just you know, what are we gonna do with the the observability package? That was a big one, and that was immediately like, well, you got to like publish the whole thing again, right? Like, is that how we're gonna, you know, actually test the validity? We gotta go fix that so that we can say that hey, Polista works correctly. Like,
S
Speaker 1
10:37
like you're gonna hate that. That's exactly what we got to do. Yeah, yeah, that's
S
Speaker 2
10:41
yeah.
S
Speaker 1
10:42
So, so yeah, like I'll share my screen just to have something to look at. So the screenshot that Larry sent. If I if I was doing this ticket, the first thing I would do is look at these guys, which you probably did, and basically, you know, we have so this one here is Dependency Cruiser, which is a package that must be in Calisto, is using this Pico match, and for whatever reason, Dependency Cruiser version, whatever we're using, has a higher version of Pico match that has the severity in it. In fact, I guess these three packages do right.
S
Speaker 2
11:22
Yeah, yeah.
S
Speaker 1
11:22
So the thing that I would do is I would ax I would ax this you know this set of lines, and then I would uptick dependency cruiser, or rather see what the most up-to-date version of dependency cruiser is published on npm, and then uptick that dependency cruiser to you know version one point 1.1 whatever the next whatever the most up to date version of it
S
Speaker 2
11:48
is yeah
S
Speaker 1
11:49
and then delete my node packages or or my node modules delete my package lock and then run npm install and then after npm install I would run npm audit and see if Dependency Cruiser is still yelling about Pico match.
S
Speaker 2
12:07
Okay.
S
Speaker 1
12:08
And base and basically you can you know you can binary search it by doing like half at a time or a group at a time or all of it at once if you really wanted. It helps especially learning it to go one by one to just see, you know, okay, like I confirm dependency cruiser is happy. Now let me try this, you know, this this package and so on. But that's that's step one. And some of them are not going to be happy, right? Like let's say let's say Pico match 404. Let's say whatever dependency cruiser update still has the high severity,
S
Speaker 3
12:42
then
S
Speaker 1
12:43
we keep the sucker in place, right, and we move on to the next one. If because because basically what happened is whoever updates Dependency Cruiser, whatever company is or open source group is responsible for it, they may or may not have fixed the thing that we are trying to avoid
S
Speaker 2
13:02
sure
S
Speaker 1
13:02
like I know tar and molter have been a problem for us for a long time.
S
Speaker 2
13:07
And actually, well, if you look at that list I have below too, like molter was one that was good. It was actually fine because I started going through them, and you know, tar was yep
S
Speaker 1
13:16
sick.
S
Speaker 2
13:17
Tar tar was a problem.
S
Speaker 1
13:21
Cool. Yeah. So it sounds like you did exactly. Sounds like you did exactly what what was needed. That's awesome. And then for Pathfinder observability package. So we've got six. The only published versions 213 declares the vulnerability. Gotcha. So what we would do for this one is you're going to have to check out Pathfinder, and the reason we want to update this is because we have multiple projects using Pathfinder, right? Yes.
S
Speaker 2
13:48
Yeah.
S
Speaker 1
13:49
So it's a problem for us, but it's also a problem for Diony team or
S
Speaker 2
13:54
yeah,
S
Speaker 1
13:54
whatever other backend services are using Pathfinder. I think you know if I was to look at it real quick. Yeah, like I see it in Callisto. I see it in Triton, and and that's just of the ones I have. So like, there's there might be like Diony and other stuff might also be using it. So what you would do is exactly this process, but in Pathfinder.
S
Speaker 2
14:23
Okay.
S
Speaker 1
14:24
And we'll see if these open telemetry issues are fixed.
S
Speaker 2
14:28
Sure.
S
Speaker 1
14:28
If they are, if they are fixed, then you'll update the stuff in. You'll update those packages in Pathfinder. You do the same exact process, right? Delete the node packages, install it, see if there's the audit problems.
S
Speaker 2
14:40
Right.
S
Speaker 1
14:40
And if that fixes even one of these, then you're gonna update. You're gonna uptick the version for Pathfinder, and we'll publish a new version of Pathfinder. Then we'll come back to Calisto, uptick the version of Pathfinder and Calisto, and that should then resolve the high severities.
S
Speaker 2
15:00
Gotta love the love the churn. Awesome. Yeah, that's what
S
Speaker 1
15:05
we get for having packages that we use.
S
Speaker 2
15:07
Yeah, I know, right? It's
S
Speaker 1
15:08
like every time you think you're making your life easier by extrapolating something to a reusable package, then more tech debt that we have to maintain.
S
Speaker 2
15:16
Yeah. Well, so so here's my question, actually, is I have I haven't had a chance to even do any of these like the Pathfinder package and stuff. I mean, obviously, looks like I can just you know set up a branch, do all that. In this case, and this is where I guess kind of a. It sounds to me like we should we be opening a new ticket just to address Pathfinder in this case. You know, it's like we start refining more things. Like I guess that's the because I know that a whole bunch of other systems rely on it. So I'm like, is that the visibility we want now for this specific ticket? We're saying, hey, we're uncovering something else. You know, we're we're you know the I guess the thing is the epic was set, and it's like now we're finding more problems. You know, and I hate that scope creep vibe that we get. You know, we start doing this.
S
Speaker 1
16:02
Great question. That's why this guy's a three-pointer for these kinds of nested things. So we don't. Larry and I ran into this months ago, and we we don't want to open up a new ticket for this because the effort to fix the dependencies in Calisto needs the the effort for the Pathfinder observability package.
S
Speaker 2
16:28
Gotcha.
S
Speaker 1
16:28
So when we were looking at like, okay, let's look at severities in our services, that surfaces the problems in the packages they depend on, right?
S
Speaker 2
16:39
Sure.
S
Speaker 1
16:39
So we don't need a Pathfinder ticket because we'll identify the problems with Pathfinder when we look at Calisto. Like all of our packages, like if you think about it, like where do we touch these things? It's like we don't publish a package for the fun of it. We publish a package because it's used by any of our services. So, if there's a problem with the package, we will see it when we're updating the services. So, as long as that's true, we can update. We only need to have the updates at the service level, as opposed to like you know updating one of our lambdas where they're kind of on an island. And yes, they need, we need to look at those directly because Calisto doesn't know, or like our our backend services don't know the dependencies on those things, and they're on their own island.
S
Speaker 2
17:32
I got you. Well, that makes sense. So, so the other question I did have then, because we, it's more about I guess even how we're communicating to Carl, DevOps side. Usually we have a release tag. We're communicating all these things. We have like you know we're usually aggregating at the end and saying here's what we're doing for our next release kind of deal. And I think that's the thing that I would want to want to make sure is that you know I feel like sometimes we're very explicit. We're like hey this ticket for this thing, so that we can look at that ticket and know exactly. And then the thing I'm just thinking in my head is, I don't want it to get lost. I don't want you know something from this effort to get lost in the mix of another ticket and go, hey, what's the the what was the effort? What was the deal? Like I and I think you're right. Like we're releasing it, we're going to see that dependency, and it should all kind of you know it's it's all going to know each other when we try to release Calisto, but yeah, that that was just my main concern too. It's like it gets kind of like buried a little bit, just a little bit. Yeah,
S
Speaker 1
18:28
no, you're asking the exact right questions, and to your point about you know communicating to DevOps or you know things that might get lost outside of the scope of this, so for our packages that we maintain, we developers actually publish it. So Carl doesn't need to know anything going on there. So yeah, I'll go I'll go over that process real quick, and we can obviously go over it again when you're ready for it. So workflow for you for let's say these problems are fixable in Pathfinder, right? So you do an investigation. You're like, oh yeah, open telemetry updated their shit. Let's update it. So what'll happen is you'll hold down Pathfinder. You'll do the process we talked about of removing overrides or anything like that, or just simply upticking things in pack in the package JSON. Make sure to delete the package lock JSON before you do that, because if you update the package JSON, but you don't update the package lock and you do the npm install, things can sometimes get misaligned, and we'll catch that in the quality report here, because there will be a misalignment between the package JSON and the package lock. So definitely make sure to delete the package lock always when you're doing these, so that the so the npm install can build it correctly. So you'll do that. You do that process, then you'll get a PR, or you'll do that process. And again, assuming that the problem is something that we can identify within the package JSON of Pathfinder observability, you will uptick this version here. So because it's a minor change, we'll just go to two 0.2 point 14.
S
Speaker 2
20:26
Yeah.
S
Speaker 1
20:27
And again, you have to do that before the package lock gets created. You know, or at least at the end. Like you can do your iterations, and then if it's working, delete package lock again, uptick this version, and then you, and then mpm install, do all that sort of good stuff, and that will create a new version. And you need that because, well, you'll then you have those changes. You'll make a PR, and like any other PR, you'll send it to the PR channel to be reviewed, even though, and it's a little weird, even though it's not like like you'll say it's it's to enable you'll say something to the effect of, hey, in order to enable work for 16595, I needed to update Pathfinder. Here's a PR for that, right? It's not closing out this ticket, but it's necessary to get this ticket going because you have to have this updated first.
S
Speaker 2
21:18
Yeah.
S
Speaker 1
21:19
So you get that PR up, your PR will be approved, and then you will create a tag for. Or actually, no, we don't need this. Then once it's approved, merged into main, you'll go to actions and you go to publish npm. You know, GitHub workflow will be from main, and you'll type in the version that you had. Oh, is this how we're doing this one here? I'm looking at this. I'm like, that doesn't seem. Seems different.
S
Speaker 2
21:53
So yeah, this one. Yeah, because I'm used to doing it based. Oh, maybe we do that for for the sprint and everything like that. So we're doing for perversion on this one. Okay.
S
Speaker 1
22:04
Let me see. We might have changed this. Okay. Yeah. So we are doing sembar tagging. So first, you'll create the tag, the Git shot, the sembar tag. So that's the number that we were just looking at, the 0.2 point 14, you'll create the tag with that number, not like 2024, you know, 2026,
S
Speaker 2
22:29
yeah,
S
Speaker 1
22:29
whatever, whatever,
S
Speaker 2
22:30
17.1 or whatever, yeah,
S
Speaker 1
22:33
yeah. So so you'll use the uptick value that you created here to create the tag, and then from the tagged image, you'll go over here and and then you'll do the same. You'll you'll go publish and you'll put the the tag number. Yeah, that's what it is. Okay, these used to be combined, but they are now separated. So you'll go to tag, update it with the number that you put in for the package lock. Then once that tag's created, you'll publish that tagged image to npm. So you'll put you know 0.1 point 14 here, and this will actually publish to npm, which sounds a little scary, but it's not. So it'll publish the version, but all the other published versions are still hosted And available, so Triton in this case will still be able to access 0.1.13 because that'll still be there.
S
Speaker 2
23:29
Okay.
S
Speaker 1
23:29
But by publishing this to npm, you can then go back to Callisto and in Calisto uptick the version of Pathfinder from 0.1.13 to 0.1.14. then do npm install, and we shouldn't see. And that should resolve these issues.
S
Speaker 2
23:48
Got it.
S
Speaker 1
23:49
That that'll make sense. I know it's a lot of steps.
S
Speaker 2
23:52
Yeah, no, and it's that was actually the the main piece that I was missing too was how do we inject it in there? Now I see makes perfect sense. Yeah, got to get it. We have to publish it, do a PR, all that kind of stuff, and yeah, I very clear now. That that makes perfect sense. Cool,
S
Speaker 7
24:08
cool.
S
Speaker 2
24:09
Heck yeah, man.
S
Speaker 1
24:10
Yeah, again, let let me know if you have. And that's same process for like receiver package, relay package, any package that we're leveraging in any of these services. It's the same same workflow.
S
Speaker 2
24:23
So okay, so the other thing then that just wanted to kind of I guess figure out what to do then about those other two. So if that's observability package, that's how it works for tar. What I found was that the only fix is upgrading SQLite three to six point whatever, so it's like updating to like a new version.
S
Speaker 1
24:50
Yeah. So another great question. So if if you update SQLite, if you update SQLite three, and then you update tar. Does that does that fix the issues?
S
Speaker 2
25:07
When I was looking it up, apparently that is that should be the solution for it. Yeah, like
S
Speaker 1
25:13
cool. So I would say go ahead and try that.
S
Speaker 2
25:15
Okay.
S
Speaker 1
25:16
And because it's a major change with SQLite three. Make sure that you can still use the application, right? So, like, make those updates poke around. Make those updates, then actually run Calisto, run Atlas, and see if you can upload a file, create a proceeding, modify some stuff.
S
Speaker 2
25:38
I was gonna say even running a script through DBEVer just to kind of see if it like is that going to be would that be a similar kind of you know just injecting stuff like that or should I be like can't go to Callisto and like try and like upload directly things like that like yeah I've never tested that before so
S
Speaker 1
25:55
yeah no no definitely testing it as the application runs is the move so we're updating SQLite three within Calisto, which is just the package that Calisto is using to communicate with Deep Beaver.
S
Speaker 2
26:10
Okay.
S
Speaker 1
26:10
So it's not actually changing anything at the database level. It's changing like the drivers or or you know the different mechanisms with which Calisto communicates with the with the database, which fully could break. Like updating this, it might cause unforeseen issues with like how our databases are registered and things like that. So,
S
Speaker 2
26:36
okay,
S
Speaker 1
26:37
good call out. Yeah, that's what I was. I think
S
Speaker 2
26:39
yeah, I'm like thinking in my head, how do I summarize what I was trying to ask? Like, what are the boundaries? And now I know. So okay, that's it's a much more breaking thing that I didn't I did not realize. Okay, I'll definitely keep my eye out for that. And I'm trying to remember the. I mean, Swagger isn't that big a deal. It's. I mean, I don't know. I can try it out and see what happens.
S
Speaker 1
27:05
Yeah, that's exactly that, and that's that's why we have these tasks as a as a monthly thing because, like, you know, you can imagine this is one month of changes. Imagine like three months. Imagine trying to do this with like three months of breaking shit. Yeah, it's like we we need to maintain these. It's kind of like getting your getting your engine checked. Yeah, do it for regular cadence before everything starts breaking.
S
Speaker 2
27:28
Yeah, yeah, no, that makes that makes sense, man. Cool. Yeah, then I'll I'll keep on keep on poking at this one, and we'll we'll see where it takes me. On that note, then, dude, I was actually gonna ask you something else because obviously we have all these PRs up there, and the one time you had started like calling out like, "Hey, go check the like you know you were kind of delegating responsibilities. Hey, you go check this, you go check that. And at one point, I had even set up for myself like a a quick you know agent little script just to say, "Hey, go pull all the you know what do we have in our repos right now? What's open? What's pending? I was like, oh, let me just go see that. Obviously, go about doing that, but you know, it becomes like a we have this problem in the internal team too. Like they'll they'll do like cherry picking, be like, hey, this one looks easy, I'll take that one. You know, like things that you can just go knock off the list. So I was just wondering like if there is like a protocol like top down do we just choose like how do we throw a dart at my screen like what's what's the best move
S
Speaker 1
28:28
good good question freaking full of good questions today so two variables right so I took I took a peek, and everything that's ready, all the PRs that are ready for review are claimed or have comments already.
S
Speaker 2
28:52
Okay.
S
Speaker 1
28:52
Which I think did you claim one of them? I had people put eyes on stuff. No, I can't. Oh, you're good. You're good. Yeah. So basically, the the way that I do it is I'm looking at. I'll pop in here and I'll look at the oldest PR. That's kind of the rule of thumb is like whatever's the oldest has been sitting for long enough where it's like we want to we want to close that out first, right? Because that person's been sitting for a while, and yeah, when PRs sit for too long, other shit gets merged into main.
S
Speaker 2
29:27
Yeah,
S
Speaker 1
29:27
it can sometimes cause breaking stuff. Like I had, I personally had a PR that sat for like two weeks. I think while Larry was on vacation.
S
Speaker 2
29:34
Yeah,
S
Speaker 1
29:35
and I had to keep merging main and handling merge conflicts and shit because it wasn't getting reviewed.
S
Speaker 2
29:42
Yeah, I actually just did that yesterday with the one that I because I've been working on that 16 403, and when I tried to merge to main, because it's like yeah at this point because you've said it to me so many times now that I'm like like shit got to do that got to got to get in there. It was like I mean obviously because it's like all the merges and stuff, but I was like 50 commits behind, and I was like, "Shh! Because when I first pulled it open, I was like, "Oh my god, okay, let's go fix that. And it definitely caused some problems. Like it really did. Like I'm like I'm just continually work. Like I'm having to do more work on the work I already did. So yeah, and I could imagine that
S
Speaker 1
30:17
happens like two or three more times while it's while it's sitting. So
S
Speaker 2
30:20
yeah, yeah, we definitely
S
Speaker 1
30:21
definitely take it by the take it by the oldest PR that's that's open
S
Speaker 2
30:28
okay
S
Speaker 1
30:29
and what was I gonna say I had a thought yeah oldest PR that's open that's ready to go. Like I reached out to Jerry. This is actually a draft PR, so he's not quite ready for it yet. Yeah. But yeah, getting the oldest one, and then also like, you know, calling a spade a spade. You know, I know you're still not not green, but greener. Sure. So if something feels like way too big of a PR to like review, review, or you know whatever, no judgment on being like, oh man, this one's like fucking 100 files, whereas this other PR is like, I just did a review for Lana that had like three files changed. Sure.
S
Speaker 2
31:18
Yeah.
S
Speaker 1
31:18
So like, if something seems a little too weighty, or something that you're not confident that you'll be able to QA. Like, feel free to cherry pick in that regard, and that's really fair.
S
Speaker 2
31:28
That's fair. Yeah, I don't think I've seen anything that large. I'm sure we'll get there, or we have had somebody. But you know, most things I see are getting that 20 some file, and I'm like, okay, it's gonna take a minute.
S
Speaker 1
31:38
Yeah, we we it's it's healthy to have small PRs, but yeah, you know sometimes things happen. Yeah, that that's that's basically it. The
S
Speaker 2
31:48
um the other thing that actually now that you're saying this though, when we do get, because I just did 116. 403 was both Atlas and Callisto. Atlas friend was also part of that ticket. So, if somebody were to pick something up, should I be checking other branches to see if they have an adjacent ticket? It's like, you know, so be like, hey, I'm see, I'm going to pick up this one. I should also go pick up that other just to be safe to make sure, because you want to release them probably at the same time and not have any
S
Speaker 1
32:17
1,000% So, so what I'll what I'll do is like I'll look. Well, first you can also check the PR channel and kind of scroll up and like we have you know the little emojis or whatever to mark if someone else has been if something's been approved. We typically do the approved. We'll sometimes do the eyes if people are looking at it, but hit that PR channel and see if, like, like that's honestly where I look before I look at the actual repos themselves.
S
Speaker 2
32:53
Yeah, yeah.
S
Speaker 1
32:54
Because in in the PR channel, like Lana or Jerry will say like, "Hey, PR is for ticket 123, and there's Caliso and there's Atlas and maybe there's also you know Europa if they're doing something with audit. So that's for the developer to yeah, it's the developer's responsibility to like post all the repos that are touched by that ticket. So you shouldn't have to hunt for them,
S
Speaker 3
33:22
right?
S
Speaker 1
33:23
But yeah, if you are reviewing any ticket, you do you are taking on however many PRs are part of that. Because yes, if someone merges Atlas but doesn't merge Calisto, or like yeah, don't don't approve Callisto before approving Atlas. Like do it at the same time. At
S
Speaker 2
33:38
the same time, because if
S
Speaker 1
33:39
you you can see it's like if if we do that and then someone's trying to run merge main from Atlas and they're like oh wait Atlas is crashing because it's expecting this endpoint that doesn't exist because the Calisto hadn't been merged so yeah they definitely if they're related tickets they gotta move together
S
Speaker 2
33:58
got it yeah no that's fair it's fair so always make sure again. My head, I'm already making the checklist. Like, check, see if each one is going to be first of all. Yeah, are they both up to with main? Then do a review. Then you know, make sure you're doing them both at the same time. Keep it all together. Keep it in line. Check.
