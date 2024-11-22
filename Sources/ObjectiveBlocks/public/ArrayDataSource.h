#import <TargetConditionals.h>

#import <Foundation/Foundation.h>
#import "CommonDataSource.h"

#if TARGET_OS_PHONE
#import <UIKit/UIKit.h>

/**
 A `UITableViewDataSource` implementation using an `NSArray` as a base.

 :param: idinitWithItems Preferred initializer
 */
@interface ArrayDataSource : NSObject<UITableViewDataSource>

/**
 *  Initializer
 *
 *  @param anItems             the array of data
 *  @param aCellIdentifier     the cell identifier
 *  @param aConfigureCellBlock the block to configure cells
 *
 *  @return a newly instanciated data source
 */
- (id)initWithItems:(NSArray *)anItems
     cellIdentifier:(NSString *)aCellIdentifier
 configureCellBlock:(TableViewCellConfigureBlock)aConfigureCellBlock;

/**
 *  Returns the item at the given indexPath.
 *
 *  @param indexPath indexPath of the object to return (section is ignored, only
 *                   row is used)
 *
 *  @return the item at the given indexPath.
 */
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

@end
#endif
