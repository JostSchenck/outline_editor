import 'package:outline_editor/src/outline_editor/document_changes.dart';
import 'package:super_editor/super_editor.dart';

/// The merge policies that are used in the standard [Editor] construction.
const defaultOutlineEditorHistoryMergePolicy = HistoryGroupingPolicyList(
  [
    mergeRepeatSelectionChangesPolicy,
    // mergeTreenodeCreationsPolicy,
    mergeRapidTextInputPolicy,
  ],
);

const mergeTreenodeCreationsPolicy = MergeTreenodeCreationsPolicy();

class MergeTreenodeCreationsPolicy implements HistoryGroupingPolicy {
  const MergeTreenodeCreationsPolicy();
  @override
  TransactionMerge shouldMergeLatestTransaction(
      CommandTransaction newTransaction,
      CommandTransaction previousTransaction) {
    // TODO: implement shouldMergeLatestTransaction
    if (newTransaction.changes
        .where(
          (editEvent) =>
              editEvent is DocumentEdit &&
              editEvent.change is TreenodeDocumentChange,
        )
        .isNotEmpty) {
      return TransactionMerge.doNotMerge;
    }
    return TransactionMerge.noOpinion;
  }
}
