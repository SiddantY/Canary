# ECE 411: mp_ooo GUIDE

## Out-of-Order RISC-V Processor

> The software programs described in this document are confidential
> and proprietary products of Synopsys Corp. or its licensors. The
> terms and conditions governing the sale and licensing of Synopsys
> products are set forth in written agreements between Synopsys Corp.
> and its customers. No representation or other affirmation of fact
> contained in this publication shall be deemed to be a warranty or
> give rise to any liability of Synopsys Corp. whatsoever. Images of
> software programs in use are assumed to be copyright and may not be
> reproduced.
> 
> This document is for informational and instructional purposes only.
> The ECE 411 teaching staff reserves the right to make changes in
> specifications and other information contained in this publication
> without prior notice, and the reader should, in all cases, consult
> the teaching staff to determine whether any changes have been made.

---

**This document, GUIDE.md, provides some extra resources and tips for the MP. For
strictly the specification and rubric, see [README.md](../README.md). For more details
on out-of-order processors in general, see [WHAT_IS_AN_OOO.md](WHAT_IS_AN_OOO.md)**

# Getting Started

## Working as a Group

For this assignment, you must work in a group of three people. It will be your responsibility to work on the assignment as a team. Every member should be knowledgeable about all aspects of your design, so do not silo responsibilities and expect everything to work when you put the parts together. Good teams will communicate often and discuss issues (either with the design/implementation or with teamwork) that arise in a timely manner.

To aid collaboration, we provide a private Github repository that you can use to share code within your team and with your TA.

Part of working well as a team is being courteous to the rest of the team, even when you plan to drop the class. We ask that you let TAs and the rest of your team know as soon as possible if you plan to drop ECE 411, so we can reassign other people and minimize the number of issues later in the semester.

## Starter Code

Your repository may not be immediately available as team assignments need to be finalized, and then the repositories are all created manually. You will be able to find the repository in the same location as your MP repository when it is ready. The repositories will be up in time for the first checkpoint.

## Mentor TAs

Each group will be assigned a mentor TA. You will have regular meetings with your mentor TA, so that they know how your project is doing and any major hurdles you have encountered along the way. You must meet with your mentor TA at least once every week. Scheduling these meetings is your responsibility. Check with your mentor TA for their preferred scheduling method/availability.

In your first meeting with your mentor TA, you will review your paper design for your basic pipeline and discuss your goals for the project. Before this meeting, you should have discussed in detail with your team about what design options you plan to explore. Your mentor TA may advise against certain options, but you are free to work on whatever you like. As the project progresses, you may find that your goals and your design change. This is normal and you are free to take the project in a direction that interests you. However, you must keep your mentor TA up to date about any changes you have made or plan to make.

In order to get the most out of your relationship with your mentor TA, you should approach the relationship as if your group has been hired into a company and given the mp_ooo design as a job assignment. A senior engineer has been assigned to help you stay on schedule and not get overwhelmed by tool problems or design problems. Do not think of the TA as an obstacle or hostile party. Do not try to "protect" your design from the TA by not allowing him or her to see defects or problem areas (your TA is there to help!). Do not miss appointments or engage in any other unprofessional conduct. Your mentor TA should be a consulting member of your team, not an external bureaucrat.

## Resources

Here are some resources to help with your design process:

- [RISC-V ISA Manual](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
- [HP1] *Computer Organization and Design RISC-V Edition: The Hardware Software Interface* by David A. Patterson and John L. Hennessy
- [HP2] *Computer Architecture: A Quantitative Approach (6th Ed.)* by John L. Hennessy and David A. Patterson
- [RISCV-BOOM Documentation](https://docs.boom-core.org/en/latest/) - This is a more advanced out-of-order RISC-V processor designed at UC Berkeley. You may find some of the documentation useful for understanding out-of-order execution.
- [*Processor Microarchitecture: An Implementation Perspective*](https://link.springer.com/book/10.1007/978-3-031-01729-2) - This book is a good resource for understanding the details of processor microarchitecture, including out-of-order execution (both Tomasulo's algorithm and explicit renaming). It is available for free as part of the *Synthesis Lectures on Computer Architecture*.
- [Alpha 21264](https://acg.cis.upenn.edu/milom/cis501-Fall09/papers/Alpha21264.pdf) - One of the OG out-of-order processors. This used explicit register renaming.

## Testing

Throughout the MP, you will need to implement your own verification. This is extremely important as untested components may lead to failing the final test code and competition benchmarks. Remember that in many of your components, such as the register bypassing unit, the order of the instructions as well as what operands are used is crucial. You cannot just test that your processor executes each of the instructions correctly in isolation. You should try to generate test code to test as many corner cases as you can think of.

Furthermore, you should test not only correctness, but performance. We will run a number of test cases on your processor during final grading where we will confirm your program's output is correct and also measure it's performance. 

# Advice from past students

Below is some advice from past students. Although the project has changed since then, their advice is still highly applicable.

On starting early:
- "Start early. Have everything that you have implemented also in a diagram, updating while you go."
- "START EARLY. take the design submission for next checkpoint during TA meetings seriously. it will save you a lot of time. Front-load your advanced design work or sufferrrrr"
- "start early and ask your TA for help."
- "Finish 3 days before it's due. You will need those 3 days (at least) to debug, which should involve the creation and execution of your own tests!"
- "Make the work you do in the early checkpoints bulletproof and it will make your life WAY easier in the later stages of MP4."
- "Don't let a passed checkpoint stop you from working ahead. The checkpoints aren't exactly a perfect balance of work."

Implementation tips:
- "Don't trust the TA provided hazard test code, just because it works doesn't mean your code can handle all data and control hazards."
- "Also, it was very good to test the cache interface with the MP 3 cache, and test the bigger cache you do (L2 cache, more ways, 8-way pseudo LRU) on the MP 2 datapath. This just makes it easier to stay out of each other's hair."
- "Run timing analyses along the way so you're not trying to meet the 100 MHz requirement on the last night."
- "Write your own test code for every case. Check for regressions."
- "Check your sensitivity lists!!"
- "Hook up the debug utilities, shadow memory and RVFI monitor, early. It helps so much later."
- "Performance counters might seem unnecessary at first, but they totally saved our competition score. Make a lot of them, and use them!!"

Possible difficulties:
-"Take the paper design seriously, we eliminated a lot of bugs before we started."
- "Integration is by far the most difficult part of this MP. Just because components work on their own does not mean they will work together."
- "The hard part about this MP is 1) integrating components of your design together and 2) edge cases. Really try to think of all edge cases/bugs before you starting coding. Also, be patient when debugging."
- "You might think it makes sense to gate the clock in certain circumstances. You are almost certainly wrong. Don't gate the clock."
- "The TAs might seem nice, but they don't give you very good testcode. Make sure to write your own."

On teamwork:
- "Try to split up the work into areas you like -- cache vs datapath, etc. You will be in the lab a lot, so you might as well be doing a part of the project you enjoy more than other parts"
- "Don't get overwhelmed, it is a lot of work but not as much as it seems actually. As long as you start at least a paper design ASAP, you should finish each checkpoint with no problems."
- "Come up with a naming convention and stick to it. Don't just name signals opcode1, opcode2, etc. For example, prepend every signal for a specific stage with a tag to specify where that signal originates from (EX_Opcode, MEM\_Opcode)."
- "Label all your components and signals as specific as possible, your team will thank you and you will thank yourself when you move into the debugging stages!"
- "Learn how to use Github well! It is very difficult to get through MP3 without this knowledge."
- "If you put in the work, you'll get results. All the tools you need for debugging are at your disposal, nothing is impossible to figure out."
- "Split up the work and plan out which parts everyone will work on each checkpoint. You can always help each other out, but make sure you know who is responsible for each part."
- "You need to be able to read each other's code. Agree on a style head of time, and don't rely on others all the time. Not being able to read code makes debugging unnecessarily difficult."
