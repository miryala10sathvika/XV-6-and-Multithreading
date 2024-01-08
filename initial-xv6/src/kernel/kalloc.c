// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}
int referenceCount[PHYSTOP/PGSIZE];
void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    referenceCount[(uint64)p/PGSIZE]=1;
    kfree(p);
  }
}
void increaseTheCount(uint64 pa)
{
  acquire(&kmem.lock);
  int page_number=pa/PGSIZE;
  if(pa>PHYSTOP || referenceCount[page_number]<1){
    
      panic("reference count error");
  }
  referenceCount[page_number]++;
  release(&kmem.lock);
}
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;
  r = (struct run*)pa;
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // // Fill with junk to catch dangling refs.
  // 
  acquire(&kmem.lock);
  int page_no=(uint64)r/PGSIZE;
  if (referenceCount[page_no]<1){
    panic("memory 'kfree' panic");
  }
  referenceCount[page_no]-=1;
  release(&kmem.lock);
  if(referenceCount[page_no]>0){
    return ;
  }
  memset(pa, 1, PGSIZE);
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r){
    int page_number=(uint64)r/PGSIZE;
    if(referenceCount[page_number]!=0){
      panic("reference count error in kalloc");
    }
    referenceCount[page_number]=1;
    kmem.freelist = r->next;
  }
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
