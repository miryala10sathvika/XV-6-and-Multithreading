
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

struct proc *que[4][NPROC];
int q_t[4]={-1,-1,-1,-1};
extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
void helpticks(){
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if (p->state==RUNNING){
      p->rtime++;
    }
    if (p->state==SLEEPING){
      p->wtime++;
      p->stime++;
    }
    if(p->state==RUNNABLE){
      p->watime++;
    }
    release(&p->lock);
}
}
int addQueue(int qno,struct proc *p){
    for(int i=0; i<q_t[qno];i++){
      if(p->pid==que[qno][i]->pid){
          return 1;
      }
    }
    p->que=qno;
    p->entry=ticks;
    q_t[qno]++;
    que[qno][q_t[qno]]=p;
     if(p->pid>2 && p->pid<13)
    printf("Process with PID %d added to Queue %d at %d\n", p->pid-2, qno,ticks);
    return 0;
}
int deleteQueue(int qno,struct proc *p){
  int r=0;
  int foundProcess=-1;
  for(int i=0;i<=q_t[qno];i++){
    if(que[qno][i]->pid==p->pid){
      foundProcess=1;
      r=i;
      break;
    }
  }
  if(foundProcess==-1){
    return -1;
  }
  for(int i=r;i<q_t[qno];++i){
    que[qno][i]=que[qno][i+1];
  }
  q_t[qno]--;
  //printf("Process with PID %d is removed from Queue %d at %d\n", p->pid, qno,ticks);
  return 1;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  p->clktik=ticks;
  p->rtime=0;
  p->wtime=0;
  p->etime=0;
  p->dyna_priority=0;
  p->stat_priority=50;
  p->watime=0;
  p->stime=0;
  for(int i=0;i<4;i++){
    p->qticks[i]=0;
  }
  p->sched_times=0;
  p->rbi=15;
  p->currticks=0;
  p->que=0;
  p->wmlfq=0;
  p->runnum=0;
  p->entry=0;
  
  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;
#ifdef MLFQ
  deleteQueue(p->que,p);
#endif
  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
int set_priority(int pid , int priority){
  int found=-1;
  for(struct proc *p=proc;p<&proc[NPROC];p++){
    acquire(&p->lock);
    if(p->pid==pid){
      found=p->stat_priority;
      p->stat_priority=priority;
      if(p->rtime+p->stime==0){
        p->rbi=15;
        p->rtime=0;
        p->stime=0;
      }
      else{
        int x=(int)(((3*p->rtime-p->stime-p->watime)/(p->rtime+p->stime+p->watime+1))*50);
        if(x>0){
          p->rbi=x;
        }
        else{
          p->rbi=0;
        }
        p->rtime=0;
        p->stime=0;
      }
      int old_dp=p->dyna_priority;
      p->dyna_priority=(p->stat_priority+p->rbi>100?100:p->stat_priority+p->rbi);
      //printf("process %d is about to run with priority %d %d\n",pid,p->dyna_priority,old_dp);
      if(old_dp>p->dyna_priority){
        release(&p->lock);
        yield();
      }
      else{
      //printf("process %d is about to run with priority %d\n",pid,p->dyna_priority);
      release(&p->lock);
      break;
      }
    }
    else{
    release(&p->lock);
    }
  }
  return found;
}
void
scheduler(void)
{
  struct cpu *c = mycpu();
  c->proc = 0;
   for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
#ifdef RR
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      //printf("hai");
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        //printf("process %d is running with priority at %d\n",p->pid,ticks);
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    } 
#endif
#ifdef FCFS
              struct proc *p;
              struct proc *min_p = 0;
              int min_time = ticks + 1;
              for(p = proc; p < &proc[NPROC]; p++) {
                acquire(&p->lock);
                if(p->state == RUNNABLE && p->clktik < min_time) {
                  if(min_p) release(&min_p->lock);
                  min_p = p;
                  min_time = p->clktik;
                }
                else release(&p->lock);
            }
            if(min_p != 0) {
              // Switch to the process with the minimum creation time.
              //printf("process %d is running with priority at %d\n",min_p->pid,ticks);
              min_p->state = RUNNING;
              c->proc = min_p;
              swtch(&c->context, &min_p->context);
              // Process is done running for now.
              // It should have changed its p->state before coming back.
              c->proc = 0;
              release(&min_p->lock);
            }
#endif
#ifdef MLFQ
              struct proc *p=0;
              for(p = proc; p < &proc[NPROC]; p++) {
                if(p->que==0){
                  addQueue(0,p);
                }
            }
            p=0;
            for(p = proc; p < &proc[NPROC]; p++) {
             // acquire(&p->lock);
            int aging=ticks-p->entry;
            if (aging>28){
               deleteQueue(p->que,p);
               p->entry=ticks;
               p->currticks=0;
               p->wmlfq=0;
               //printf("1 Process %d moved to queue %d from %d due to age %d at %d\n", p->pid, p->que,0, aging, ticks);
               if(p->que>0){
               addQueue(p->que-1,p); 
                }
               else{
                addQueue(0,p);
               }
            }
            //release(&p->lock);
              }
             p=0;
             for(int i=0;i<4;i++){
              if (q_t[i]==-1)
                continue;
              for(int j=0;j<=q_t[i];j++){
                //acquire(&que[i][j]->lock)
                if(que[i][j]->state==RUNNABLE){
                  p=que[i][j];
                  deleteQueue(p->que,p);
                  break;
                }
                //release(&que[i][j]->lock)
              }
             }
        if(p!=0 && p->state==RUNNABLE){
            p->runnum++;
            p->qticks[p->que]++;
            p->state=RUNNING;
            //printf("Scheduling PID %d from Queue %d with current tick %d at tick %d\n",p->pid, p->que, p->currticks,ticks);
            acquire(&p->lock);
            c->proc=p;
            swtch(&c->context, &p->context);
            c->proc=0;
            release(&p->lock);
            if(p!=0 && p->state==RUNNABLE){
              if(p->changequeue==1){
                p->changequeue=0;
                p->currticks=0;
                p->wmlfq=0;
                p->entry=ticks;
                if(p->que<3){
                  p->que++; 
                }
                else
                {
                  p->currticks=0;
                }
               // printf("1 que no:%d",p->que);
                addQueue(p->que,p);
              }
            }
            //release(&p->lock);
        }
#endif
#ifdef PBS
  int maxi_priority = 0;
  struct proc *p = 0;
  int x = 0;
  struct proc *run_proc = 0;
  for (p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if (p->state == RUNNABLE) {
      if (p->rtime + p->stime > 0) {
        x = (int)(((3 * p->rtime - p->stime - p->watime) / (p->rtime + p->stime + p->watime + 1)) * 50);
      }
      if (x > 0) {
        p->rbi = x;
      } else {
        p->rbi = 0;
      }
      p->dyna_priority = (p->stat_priority + p->rbi > 100 ? 100 : p->stat_priority + p->rbi);

      if (run_proc == 0 || maxi_priority > p->dyna_priority ||
          (maxi_priority == p->dyna_priority && run_proc->sched_times > p->sched_times) ||
          (maxi_priority == p->dyna_priority && run_proc->sched_times == p->sched_times && run_proc->clktik > p->clktik)) {
        // Update the maximum priority process
        maxi_priority = p->dyna_priority;
        if (run_proc) {
          release(&run_proc->lock);
        }
        run_proc = p;
      } else {
        // Release the lock for the current process if it's not selected
        release(&p->lock);
      }
    } else {
      // Release the lock for non-RUNNABLE processes
      release(&p->lock);
    }
  }

  if (run_proc != 0) {
    if (run_proc->state == RUNNABLE) {
      //printf("process %d is running with priority at %d\n", run_proc->pid, ticks);
      run_proc->sched_times += 1;
      run_proc->state = RUNNING;
      c->proc = run_proc;
      swtch(&c->context, &run_proc->context);
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&run_proc->lock);
    }
  }
#endif
  }
}
// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
#ifdef MLFQ
    p->wmlfq=0;
    p->currticks=0;
#endif
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
#ifdef MLFQ
        p->wmlfq=0;
        addQueue(p->que,p);
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->clktik - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}
int
getps(void) 
{
    struct proc *p;
    int ret = -1;
    printf("Name\ts_time\n");
    for (p = proc; p < &proc[3]; p++)
    {
      acquire(&p->lock);
      printf("%s \t %d\n", p->name,p->wtime);
      release(&p->lock);
   }
    return ret;
}
