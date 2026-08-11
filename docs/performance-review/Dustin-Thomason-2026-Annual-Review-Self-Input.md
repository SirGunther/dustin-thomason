# 2026 Annual Review Self-Input

**Dustin Thomason**  
**Submitted:** August 7, 2026

---

Jim,

Thanks for giving me the opportunity to put this together. I've tried to keep it focused on the three things you asked for: my performance this year, the people who would be helpful to hear from, and where I would like to go next year. Since some of this work started before you and I began working together, I've included a little context where I thought it would be useful.

I want my work to be technically strong, useful to the people around me, and supportive of the team as a whole. Much of my best work sits between systems and people: turning loosely defined needs into something buildable and giving others the context they need to succeed. I want to continue taking on substantial problems, expand into frameworks and areas of development that are new to me, and deepen my contribution across the systems and teams involved.

## Performance this year

Looking back, I believe I performed well in three areas: taking initiative on opportunities that had not yet become formal assignments, learning unfamiliar systems well enough to deliver in them, and helping people turn unclear needs into work the team can realistically accomplish. The biggest theme has been expanding what I am capable of while looking for places where that growth can create real value for the company.

Nova is the clearest example, but why it matters to this year's performance is easier to understand with a little history. The idea surfaced roughly six years ago, when I was a trainer in the field and Nate Mollick and I were talking about how other companies operated. A few years later, after Shaye became the video manager and I became Head of Special Projects, we revisited it. Videographers were spending significant time transcoding files and dealing with frequent errors. HandBrake made the process more manageable, while FFmpeg remained part of a longer-term vision that required development support we did not yet have. The need—and the idea—remained.

Being part of Product Development changed those conditions. I had broader development support, growing AWS experience, and closer contact with the people affected by the problem. In October 2025, around the time I began prototyping, I attended the Litigation Technology picnic and asked the team what mattered to them. Joey's comments about retention, together with what I heard about the stress of transcoding files at all hours of the night, made clear that improving the process could make the work more sustainable—not just more technically efficient.

That context led me to ask how practical an AWS-based solution could be. I built an initial proof of concept on my own time around October 2025, both to challenge myself and to determine what was merely possible versus what was practical. At a projected volume of roughly 900 transcodes per month, the analysis made the scale of the effort, the cost attached to it, and the value of returning that time to videographers clear. This was not an assigned initiative, and Gregg was the only person I initially told about the prototype. I presented the analysis to him as a substantial win for our department. We then brought it to Joey and the Litigation Technology team, whose interest and confirmation of the need helped us move it forward together. The first formal project commit followed in December, and Nova is now in beta testing and nearing its first launch.

That work involved a substantial amount of learning for me, particularly around AWS, Fargate tasks, and where Fargate is a better fit than EC2. The initial design changed as we learned more, which I view as a healthy part of the process. Proving out Nova also exposed infrastructure we needed between Atlas and Callisto. Xavier and I worked closely on the messaging and authorization work that became the orbital docking protocol. I am proud that Nova began as an idea I chose to investigate, but I also recognize that getting it this far has depended on the knowledge and effort of several people.

This reflects a broader pattern in how I contribute: I use self-directed prototypes to test ideas, make their value concrete, and give the company something real to evaluate. Having room for that kind of exploration keeps me engaged, expands what I can do, and can turn curiosity into practical value.

Roughly four years of Power Platform development left a great deal of system knowledge concentrated with me, and reducing that concentration has been a deliberate goal this year. I recommended Jaimie from among several candidates because I believed she was the strongest fit, and she helped us form Team Tesseract. We work through the systems together: I explain the architecture and the reasoning behind it, we discuss how something should change, and I give her a piece to own and review the result directly as she takes on more responsibility. Our joint work on the Operations Job Board and Automated Double Board has been part of that transition. Much of this work does not appear in commit history, but it gives those systems a more sustainable support structure and allows me to take on Atlas responsibilities without leaving a gap.

From a technical perspective, Atlas has changed not just what I know, but how I approach systems. When I learn an architectural pattern, I try to understand the theory behind it and apply it broadly rather than limit it to one platform. That has made my Power Platform work more deliberate about security, scalability, predictability, and maintenance. One example is the file-transfer path between AWS and our Microsoft environment. My work included writing Azure Functions and helping establish the gateways and HTTP triggers that allow files to move into SharePoint and OneDrive, along with maintaining and correcting that transfer path as it developed.

A significant part of ownership is the less visible work of keeping systems dependable after they launch. Over the past year, that has included working through the ReporterBase 9 connection going offline, OMTI's 60-second query limit, changes in how SharePoint records were being detected, and recurring synchronization failures. Jaimie and I have had to revisit query structures, reduce processing loads, and improve recovery behavior as patterns that worked under earlier conditions stopped holding up.

Cross-service file movement has required the same kind of attention. CloudHQ transfers could complete while Hubble still reported processing errors, and the Atlas-to-OneDrive path had cases where files reached the correct location with the wrong filename. I worked across the affected systems and teams to identify which layer was failing, correct the logic, rerun affected work, and verify the result. These are not headline projects, but they represent a large part of what ownership means to me: when something breaks, I step into the discussion, make the problem understandable, and help keep the work moving.

An area where I want to keep improving is getting clarity earlier. A number of difficult situations this year were made harder by incomplete requirements, unclear ownership, or a missing definition of success. I have become more deliberate about asking questions and identifying constraints before implementation begins. I want to keep improving at turning those conversations into clear decisions and shared understanding without making the process heavier than it needs to be.

## Stakeholders who could provide input

The following people have seen different parts of my work and would each bring a useful perspective:

- **Larry Adams** — our work on Nova, engineering discussions, ticket development, and my approach to investigation and technical ownership.
- **Caitlin** — my work on the Operations Job Board and Automated Double Board, along with requirements and collaboration from the operations side of the business.
- **Jaimie** — our work through Team Tesseract, the Power Platform transition, mentorship, technical context, and work review.
- **Karl** — Nova architecture, environments, and my growth in AWS-based system design.
- **Xavier** — our close work on Atlas-to-Callisto messaging, authorization, and the orbital docking protocol, as well as how I collaborate on technical problems.

There are other people who could speak to individual pieces of work, but I think this group provides a fair range across technical delivery, collaboration, mentorship, and operational impact.

## Goals for next year

My first goal is to take clear technical ownership of a product area, beginning with the Nova engine. Larry has raised this as a possibility, and it is work I am strongly interested in owning. I helped develop the core system, while others handled the front end and file-transfer components. As Nova moves through beta, the engine will need additional features, templates, updates, and ongoing support. I want to be accountable for that roadmap and the system's long-term health while continuing to collaborate with the owners of the connected components.

My second goal is to shift the center of my work toward AWS, Atlas, and the related product branches we are building. Team Tesseract gives the Power Platform systems a more sustainable support structure, allowing me to focus on deeper backend and cloud architecture work. I want to continue developing products across Atlas, whether they support internal operations or are client-facing. Building something new, especially when it requires unfamiliar systems or ideas, is the kind of challenge that keeps me engaged.

I will continue refining my investigation, documentation, and workflow practices within the work I own, but I see that as an ongoing discipline rather than a separate department-wide goal.

My third goal is to define and work toward the next level of responsibility. I am interested in advancing, and I would value a clear and candid understanding of what that requires here—whether it is broader technical ownership, architectural responsibility, leadership, or some combination of those things. My goal is to leave the review process with a specific plan I can work toward and a shared understanding of what meaningful progress would look like.

I appreciate you taking the time to gather input and turn it into something useful. I am happy to go deeper on any of this in our discussion, and I am also open to where my perspective may be incomplete. I'll send the calendar invitation separately for the week of August 10.

Thanks,

Dustin
