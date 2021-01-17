#ifndef __nc_f4_hpp__
#define __nc_f4_hpp__

#include "NCAlgebras/FreeMonoid.hpp"      // for MonomEq
#include "MemoryBlock.hpp"                // for MemoryBlock
#include "NCAlgebras/Range.hpp"           // for Range
#include "NCAlgebras/Word.hpp"            // for Word
#include "NCAlgebras/OverlapTable.hpp"    // for OverlapTable
#include "NCAlgebras/WordTable.hpp"       // for Overlap, WordTable
#include "NCAlgebras/SuffixTree.hpp"      // for experimental suffix tree code
//#include "VectorArithmetic.hpp"         // for VectorArithmetic, CoeffVector, etc
#include "VectorArithmetic2.hpp"          // for VectorArithmetic, CoeffVector, etc
#include "Polynomial.hpp"                 // for Monom, ConstPolyList, Poly
#include "newdelete.hpp"                  // for VECTOR, our_new_delete

#include <deque>                       // for deque
#include <iosfwd>                      // for ostream
#include <map>                         // for map
#include <unordered_map>               // for unordered_map
#include <tuple>                       // for tuple
#include <utility>                     // for pair
#include <vector>                      // for vector

#include <tbb/tbb.h>                        // for tbb

class FreeAlgebra;
union ring_elem;

// this class contains an NCGB calculation using the F4 algorithm.
// subclasses needed:
//   WordTable/SuffixTree (used for this class and Naive algorithm)
//   OverlapTable         (used for this class and Naive algorithm)
//   F4MatrixBuilder
//   F4Matrix

class NCF4 : public our_new_delete
{
private:
  // Data structures for construction of each spair matrix
  // and data for the matrix itself.

  // memory space for monomials and words for F4 matrix.
  // PreRow is left, index of poly, right, prevReducer
  // where the entries depend on the value of prevReducer.
  // prevReducer = false: if index \geq 0, then left*mGroebner[index]*right
  //                      is the lead term of a reducer.
  //                      if index < 0, then left*mInput[-index-1]*right
  //                      is the lead term of a reducer.
  // prevReducer = true : left*mRows[i]*right is the lead term of a reducer
  // the int at the end is the index of the PreRow in the
  // corresponding vector it belongs to, which will eventually
  // be the corresponding row.
  using PreRow = std::tuple<Word, int, Word, bool,int>;

  // the int keeps track of where to put the row upon completion of the task
  using PreRowTask = std::pair<PreRow,int>;

  // make this into a std::pair of <CoeffVector,Range<int>>
  // CoefficientVector knows whether it owns it memory or not but has the similar interaface as a range
  using Row = std::pair<CoeffVector,
                        Range<int>>; // components corresponding to monomials appearing

  using Column = std::pair<Monom, int>; // monomial, pivot row for this monomial (if not -1).

  //using ColumnsVector = tbb::concurrent_vector<Column>;
  using ColumnsVector = std::vector<Column>;
  using RowsVector = tbb::concurrent_vector<Row>;
  using PreRowFeeder = tbb::parallel_do_feeder<NCF4::PreRow>;
  using MonomialHash = tbb::concurrent_unordered_map<Monom, std::pair<int,int>, MonomHash, MonomHashEqual>;

  // data
  const FreeAlgebra& mFreeAlgebra;
  const ConstPolyList mInput;
  
  WordTable mWordTable;
  //SuffixTree mWordTable;
  OverlapTable mOverlapTable;
  PolyList mGroebner;

  bool mIsGraded;
  int mTopComputedDegree;
  int mHardDegreeLimit;


  MemoryBlock mMonomialSpace;
  MonomEq mMonomEq;
  MonomHashEqual mMonomHashEqual;
  MonomHash mMonomHash;

  // The pair in this unordered_map is (i,j) where:
  //    i is the column number
  //    j is the row that reduces it (and -1 if there is no such row).

  // TODO(?): we should change this to have keys 'Word's rather than 'Monom's since its unordered.
  // but we would have to update MonomHashEqual a bit
  MonomialHash mColumnMonomials;
  std::vector<PreRow> mReducersTodo;
  std::vector<PreRow> mOverlapsTodo;
  // mColumns[c].second is the row which will reduce the c'th monomial (unless it is -1).
  ColumnsVector mColumns;

  // these should be std::vectors (or changeable)
  RowsVector mRows;
  RowsVector mOverlaps;

  int mFirstOverlap; // First non pivot row row (and all later ones are also non-pivot rows).

  // storing previous F4 information
  //VECTOR(Row) mPreviousRows;
  //std::vector<Row> mPreviousRows;
  RowsVector mPreviousRows;
  ColumnsVector mPreviousColumns;
  MonomialHash mPreviousColumnMonomials;
  MemoryBlock mPreviousMonomialSpace;

  // vector arithmetic class for reduction
  //const VectorArithmetic *mVectorArithmetic;
  const VectorArithmetic2 *mVectorArithmetic;

  bool mIsParallel;

public:
  NCF4(const FreeAlgebra& A,
       const ConstPolyList& input,
       int hardDegreeLimit,
       int strategy,
       bool isParallel
       );

  ~NCF4() { mMonomialSpace.deallocateAll(); mPreviousMonomialSpace.deallocateAll(); }

  const FreeAlgebra& freeAlgebra() const { return mFreeAlgebra; }

  const ConstPolyList& currentValue() const
  { 
    return reinterpret_cast<const ConstPolyList&>(mGroebner);
  }

  void compute(int softDegreeLimit);

  void displayF4Matrix(std::ostream& o) const;

  void displayFullF4Matrix(std::ostream& o) const;

  void displayF4MatrixSize(std::ostream & o) const;

private:
  void process(const std::deque<Overlap>& overlapsToProcess);

  void buildF4Matrix(const std::deque<Overlap>& overlapsToProcess);
  void parallelBuildF4Matrix(const std::deque<Overlap>& overlapsToProcess);

  void sortF4Matrix();

  void reduceF4Matrix();
  void parallelReduceF4Matrix();
  
  // FM : I had to discard const qualifiers here because I used mMonomialSpace.
  // Should I be doing this?  Two questions:  Should we make mMonomialSpace
  // mutable so changes don't trigger const errors, and should I really be
  // using mMonomialSpace anyway?
  Word createOverlapLeadWord(const Overlap& o);
  auto isOverlapNecessary(const Overlap& o) -> bool;
  auto checkOldOverlaps(Word& newLeadWord) -> void;

  void matrixReset();

  int prerowInReducersTodo(PreRow pr) const;

  // These functions are essentially from NCGroebner
  void addToGroebnerBasis(Poly * toAdd);
  void updateOverlaps(const Poly * toAdd);
  auto overlapHeft(Overlap o) const -> int;
  auto insertNewOverlaps(std::vector<Overlap>& newOverlaps) -> void;

  void reducedRowToPoly(Poly* result,
                        const RowsVector& rows,
                        const ColumnsVector& cols,
                        int i) const;
  PolyList newGBelements() const;  // From current F4 matrix.

  template<typename MemBlockLockType, typename MatrixLockType>
  void processPreRow(PreRow r,
                     MemBlockLockType& memBlockLock,
                     MatrixLockType& matrixLock,
                     PreRowFeeder* feeder,
                     bool isOverlapPreRow);
  void processPreRow(PreRow r, bool isOverlapPreRow);

  template<typename MatrixLockType>
  void processMonomInPreRow(Monom& m,
                            int* nextcolloc,
                            MatrixLockType& matrixLock,
                            PreRowFeeder* feeder);

  void preRowsFromOverlap(const Overlap& o);
  void parallelPreRowsFromOverlap(const Overlap& o);

  std::pair<bool, PreRow> findDivisor(Monom mon);

  void autoreduceByLastElement();
  ring_elem getCoeffOfMonom(const Poly& f, const Monom& m);

  template<typename LockType>
  void generalReduceF4Row(int index,
                          int first,
                          int firstcol,
                          long &numCancellations,
                          DenseCoeffVector& dense,
                          bool updatColumnIndex,
                          LockType& lock);

  void reduceF4Row(int index,
                   int first,
                   int firstcol,
                   long &numCancellations,
                   DenseCoeffVector& dense)
  {
    tbb::null_mutex noLock;
    generalReduceF4Row<tbb::null_mutex>(index,
                                        first,
                                        firstcol,
                                        numCancellations,
                                        dense,
                                        true,
                                        noLock);
  }
  
  void parallelReduceF4Row(int index,
                           int first,
                           int firstcol,
                           long &numCancellations,
                           DenseCoeffVector& dense,
                           tbb::queuing_mutex& lock)
  {
    generalReduceF4Row<tbb::queuing_mutex>(index,
                                           first,
                                           firstcol,
                                           numCancellations,
                                           dense,
                                           false,
                                           lock);
  }

  
  // return value is isFound, columnIndexOfFound
  // discard const qualifier here again because this creates a monom in mMonomialSpace
  std::pair<bool,int> findPreviousReducerPrefix(const Monom& m);
  std::pair<bool,int> findPreviousReducerSuffix(const Monom& m);

  void processPreviousF4Matrix();
};

#endif

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e  "
// indent-tabs-mode: nil
// End:
