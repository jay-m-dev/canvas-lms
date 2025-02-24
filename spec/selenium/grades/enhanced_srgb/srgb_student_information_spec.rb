# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../../helpers/gradebook_common"
require_relative "../pages/enhanced_srgb_page"
require_relative "../pages/gradebook_cells_page"

describe "Screenreader Gradebook Student Information" do
  include_context "in-process server selenium tests"
  include_context "reusable_gradebook_course"
  include GradebookCommon

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_5
    student_submission
    assignment_1.grade_student(student, grade: 3, grader: teacher)
  end

  context "in Student Information section" do
    before do
      course_setup
      user_session(teacher)
      EnhancedSRGB.visit(test_course.id)
    end

    it "allows comments in Notes field" do
      EnhancedSRGB.select_student(student)
      EnhancedSRGB.show_notes_option.click
      replace_content(EnhancedSRGB.notes_field, "Good job!")
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.notes_field)

      expect(EnhancedSRGB.notes_field).to have_value("Good job!")
    end

    it "displays student's grades" do
      EnhancedSRGB.select_student(student)
      expect(EnhancedSRGB.final_grade.text).to eq("30% (3 / 10 points)")
      expect(EnhancedSRGB.assign_subtotal_grade.text).to eq("30% (3 / 10)")
      expect_new_page_load { EnhancedSRGB.switch_to_default_gradebook }
      expect(Gradebook::Cells.get_total_grade(student)).to eq("30%")
    end

    context "displays no points possible warning" do
      before do
        @course.apply_assignment_group_weights = true
        @course.save!
        EnhancedSRGB.visit(test_course.id)
      end

      it "with only a student selected" do
        EnhancedSRGB.select_student(student)

        expect(EnhancedSRGB.no_points_possible_warning).to include_text("Score does not include assignments from the group")
      end

      it "with only an assignment is selected" do
        EnhancedSRGB.select_assignment(assignment_5)

        expect(EnhancedSRGB.assignment_group_no_points_warning).to include_text("Assignments in this group have no points")
      end
    end
  end
end
