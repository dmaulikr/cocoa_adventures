//
//  MyDocument.m
//  RaiseMan
//
//  Created by Jacob Good on 8/14/08.
//  Copyright Jacob Good 2008 . All rights reserved.
//

#import "MyDocument.h"
#import "Person.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
		employees = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
	[self setEmployees:nil];
	[super dealloc];
}

- (void) setEmployees:(NSMutableArray *) a
{
	if (a == employees)
		return;
	
	for (Person *person in employees)
		[self stopObservingPerson:person];
	
	[a retain];
	[employees release];
	employees = a;
	
	for (Person *person in employees)
		[self startObservingPerson:person];
}

- (void) insertObject:(Person *)p inEmployeesAtIndex:(int)index
{
	NSLog(@"adding %@ to %@", p, employees);
	// Add the inverse of this operation to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromEmployeesAtIndex:index];
	
	if (![undo isUndoing])
		[undo setActionName:@"Insert Person"];
	
	// Add the person to the array
	[self startObservingPerson:p];
	[employees insertObject:p atIndex:index];
}

- (void) removeObjectFromEmployeesAtIndex:(int)index
{
	Person *p = [employees objectAtIndex:index];
	NSLog(@"removing %@ from %@", p, employees);
	// Add the inverse of this operation to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:p	inEmployeesAtIndex:index];
	
	if (![undo isUndoing])
		[undo setActionName:@"Delete Person"];
	
	[self stopObservingPerson:p];
	[employees removeObjectAtIndex:index];
}

- (void) stopObservingPerson:(Person *) person
{
	[person removeObserver:self	forKeyPath:@"personName"];
	[person removeObserver:self forKeyPath:@"expectedRaise"];
}

- (void) startObservingPerson:(Person *) person
{
	[person addObserver:self forKeyPath:@"personName" options:NSKeyValueObservingOptionOld context:NULL];
	[person addObserver:self forKeyPath:@"expectedRaise" options:NSKeyValueObservingOptionOld context:NULL];
}

- (void) changeKeyPath:(NSString *)keyPath
			  ofObject:(id)obj
			   toValue:(id)newValue
{
	// setValue:forKeyPath: will cause the key-value observing method
	// to be called. which takes care of the undo stuff
	[obj setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)obj
						change:(NSDictionary *)change
					   context:(void *)context
{
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	
	if (oldValue == [NSNull null]) {
		oldValue = nil;
	}
	
	NSLog(@"oldValue = %@", oldValue);
	
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
	[undo setActionName:@"Edit"];
}

- (BOOL)endEditing
{
	NSWindow *w = [tableView window];
	BOOL editingEnded = [w makeFirstResponder:w];
	if (!editingEnded) {
		return NO;
	}
	NSUndoManager *undo = [self undoManager];
	if ([undo groupingLevel]) {
		[undo endUndoGrouping];
		[undo beginUndoGrouping];
	}	
	return YES;
}


- (IBAction)createEmployee:(id)sender
{
	// If a field is being edited, end editing
	if ([self endEditing] == NO) {
		return;
	}
	
	Person *p = [employeeController newObject];
	[employeeController addObject:p];
	
	// In case the user has sorted the content array
	[employeeController rearrangeObjects];
	
	// Find the row of the new object
	NSArray *a = [employeeController arrangedObjects];
	int row = [a indexOfObjectIdenticalTo:p];
	
	// Start editing in the first column
	[tableView editColumn:0
					  row:row
				withEvent:nil
				   select:YES];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

@end
