# Annual Review Self-Input — Compensation-Positioned Experiment

**Status:** Secondary working draft. Not sent. The primary voice-baseline draft remains unchanged.

## Private compensation calibration — do not send this section

- **Market-aligned base target:** **$140,000**
- **Opening negotiation anchor:** **$150,000**
- **Lower immediate adjustment worth considering:** approximately **$120,000–$125,000**, but only with a written role, milestone, and compensation path to $140,000 within 6–12 months
- **Role basis:** senior-level software/product engineering with cloud-system ownership—not compensation as a continuation of the current salary
- **Why $140,000:** the national median is $133,080 for software developers and $130,390 for computer network architects. Current Washington-area senior software benchmarks are higher, including approximately $144,000 through Built In and $157,500 through Indeed. Robert Half's 2026 national midpoint for DevOps engineers is $145,750 and identifies cloud computing, security, and architecture among the skills employers pay more for.
- **Negotiation principle:** evaluate the market value of the role, scope, and expected ownership. Do not treat the appropriate salary as a percentage increase from the current ~$80,000 base.

Sources: [BLS — Software Developers](https://www.bls.gov/ooh/computer-and-information-technology/software-developers.htm), [BLS — Computer Network Architects](https://www.bls.gov/ooh/computer-and-information-technology/computer-network-architects.htm), [Built In — Senior Software Engineer, Washington DC](https://builtin.com/salaries/us/washington-dc/senior-software-engineer), [Indeed — Senior Software Engineer, Washington DC](https://www.indeed.com/career/senior-software-engineer/salaries/Washington--DC), [Robert Half — 2026 Technology Salary Trends](https://www.roberthalf.com/us/en/insights/research/technology-salary-trends)

---

## Draft response

Jim,

Thanks for giving me the opportunity to put this together. I've kept it focused on the three things you asked for: my performance this year, the people who would be helpful to hear from, and where I would like to go next year. Since some of this work started before you and I began working together, I've included context where it helps explain the contribution.

I want my work to be technically strong, useful to the people around me, and supportive of the team as a whole. Much of my best work sits between systems and people: identifying an opportunity, making it concrete enough to evaluate, and giving others the context they need to succeed. I want to continue taking ownership of substantial problems and deepen my contribution across the products and teams involved.

## Performance this year

Looking back, I performed well in three areas: originating opportunities that had not yet become formal assignments, developing enough fluency in unfamiliar systems to deliver real products, and creating leverage so that important work and knowledge do not remain dependent on one person.

Nova is the clearest example, but its significance this year is easier to understand with a little history. The idea surfaced roughly six years ago, when I was a trainer in the field and Nate Mollick and I were discussing how other companies operated. A few years later, after Shaye became the video manager and I became Head of Special Projects, we revisited it. Videographers were spending significant time transcoding files and dealing with frequent errors. HandBrake made the process more manageable, while FFmpeg remained part of a longer-term vision that required development support we did not yet have.

Being part of Product Development changed those conditions. I had broader development support, growing AWS experience, and closer contact with the people affected by the problem. In October 2025, around the time I began prototyping, I attended the Litigation Technology picnic and asked the team what mattered to them. Joey's comments about retention, together with what I heard about the stress of transcoding files at all hours of the night, made clear that improving the process could make the work more sustainable—not just more technically efficient.

I built the initial proof of concept on my own time around October 2025. At a projected volume of roughly 900 transcodes per month, the analysis made the scale of the effort, the cost attached to it, and the value of returning that time to videographers clear. This was not an assigned initiative, and Gregg was the only person I initially told about the prototype. I presented the analysis to him as a substantial opportunity for the department. We then brought it to Joey and the Litigation Technology team, whose interest and confirmation of the need helped us move it forward together. The first formal project commit followed in December, and Nova is now in beta testing and nearing its first launch.

My contribution went beyond the initial idea. Building Nova deepened my work in AWS, including Fargate task design and the tradeoffs between Fargate and EC2. It also exposed missing infrastructure between Atlas and Callisto. Xavier and I worked closely on the messaging and authorization work that became the orbital docking protocol. This is a recurring way that I create value: I use self-directed prototypes to test opportunities, establish whether they are practical, and give the company something real enough to make a decision about.

Another important part of the year was making my transition from roughly four years of Power Platform ownership into Atlas sustainable. I recommended Jaimie from among several candidates because I believed she was the strongest fit, and she helped us form Team Tesseract. Jaimie and I work through the architecture and context together as she takes on more ownership, including our joint work on the Operations Job Board and Automated Double Board. This gives the Power Platform systems a stronger support structure while allowing me to take on Atlas responsibilities without leaving a gap.

Atlas has also changed how I approach systems more broadly. When I learn an architectural pattern, I try to understand the theory behind it and apply it beyond one platform. That has made my work more deliberate about security, scalability, predictability, and maintenance. One example is the file-transfer path between AWS and our Microsoft environment. My work included writing Azure Functions and helping establish the gateways and HTTP triggers that move files into SharePoint and OneDrive, along with maintaining and correcting that path as it developed.

An area where I continue to improve is getting clarity earlier. Difficult work is often made harder by incomplete requirements, unclear ownership, or a missing definition of success. I have become more deliberate about investigating constraints before implementation, documenting the reasoning behind decisions, and making the resulting knowledge easier for other people to use.

## Stakeholders who could provide input

- **Larry Adams** — our work on Nova, engineering discussions, ticket development, and my approach to investigation and technical ownership.
- **Xavier** — our close work on Atlas-to-Callisto messaging, authorization, and the orbital docking protocol, as well as how I collaborate on technical problems.
- **Karl** — Nova architecture, environments, and my growth in AWS-based system design.
- **Caitlin** — my work on the Operations Job Board and Automated Double Board, along with requirements and collaboration from the operations side of the business.
- **Jaimie** — our work through Team Tesseract, the Power Platform transition, mentorship, technical context, and work review.

This group provides a focused range across technical delivery, product development, collaboration, mentorship, and operational impact.

## Goals for next year

My first goal is to take clear technical ownership of a product area, beginning with the Nova engine. Larry has raised this as a possibility, and it is work I am strongly interested in owning. I helped develop the core system, while others handled the front end and file-transfer components. As Nova moves through beta, the engine will need additional features, templates, updates, and ongoing support. I want to be accountable for that roadmap and the system's long-term health while continuing to collaborate with the owners of the connected components.

My second goal is to shift the center of my work toward AWS, Atlas, and the related product branches we are building. Team Tesseract gives the Power Platform systems a sustainable support structure, allowing me to focus on deeper backend and cloud architecture work. I want to continue developing products across Atlas, whether they support internal operations or are client-facing. Building something new, especially when it requires unfamiliar systems or ideas, is the kind of challenge that keeps me engaged and where I believe I can create the most value.

My third goal is to formalize the next level of responsibility and ownership. I am interested in advancing into a role where broader technical ownership, architecture, product development, and team leverage are explicit expectations rather than informal additions to my work. I would like us to define what that role is, what I will own, and what measurable progress looks like.

Compensation should be part of that alignment. My current base salary is close to $80,000. Based on the scope I am already carrying, the ownership I am prepared to take on, and the market for senior software and cloud-focused engineering work, I believe **$140,000 in base salary** is an appropriate target. I recognize that this is a meaningful adjustment, but I believe the relevant comparison is the market value of the role and its responsibilities—not the percentage increase from my current salary.

I am raising this directly because the purpose of the review is to produce specific plans. If full alignment cannot happen immediately, I would like to leave the discussion with a written path that identifies the role and title, the responsibilities and outcomes expected from me, the compensation steps, and the dates attached to them.

I appreciate you taking the time to gather input and turn it into something useful. I am happy to go deeper on any of this in our discussion, and I am open to where my perspective may be incomplete. I'll send the calendar invitation separately for the week of August 10.

Thanks,

Dustin
